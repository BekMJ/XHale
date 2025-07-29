import Foundation
import CoreBluetooth
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class BLEManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var discoveredPeripherals: [CBPeripheral] = [] {
        didSet {
            print("🔍 Discovered peripherals count: \(discoveredPeripherals.count)")
        }
    }
    @Published var connectedPeripheral: CBPeripheral? {
        didSet {
            print("📱 Connected peripheral changed: \(connectedPeripheral?.name ?? "nil")")
        }
    }
    @Published var isScanning: Bool = false

    /// How long each device has been connected
    @Published var connectionDurations: [UUID: TimeInterval] = [:]

    @Published var bluetoothState: CBManagerState = .unknown

    // MARK: - Sensor Data Arrays
    @Published var temperatureData: [Double] = []
    @Published var coData: [Double] = []
    @Published var deviceSerial: String?

    var isSampling = false
    @Published var coTimestamps: [Date] = []
    @Published var temperatureTimestamps: [Date] = []
    @Published var peripheralMACs: [UUID:String] = [:]


    // MARK: - BLE UUIDs & Characteristics
    private var centralManager: CBCentralManager!
    private let sensorServiceUUID   = CBUUID(string: "0000181a-0000-1000-8000-00805f9b34fb")
    private let temperatureCharUUID = CBUUID(string: "00002a6e-0000-1000-8000-00805f9b34fb")
    private let coCharUUID          = CBUUID(string: "00002bd0-0000-1000-8000-00805f9b34fb")
    private let disServiceUUID       = CBUUID(string: "180A")
    private let serialNumberCharUUID = CBUUID(string: "2A25")

    // Hold references to characteristics for reading
    private var temperatureCharacteristic: CBCharacteristic?
    private var coCharacteristic: CBCharacteristic?

    
    // MARK: – MAC-keyed timing storage
    private var connectionStartDatesByMAC: [String: Date] = [:]
    private var connectionTimersByMAC:     [String: Timer] = [:]
    @Published var connectionDurationsByMAC: [String: TimeInterval] = [:]
    private var timerListenersByMAC: [String: ListenerRegistration] = [:]
    private var cumulativeDurationsByMAC:  [String: TimeInterval] = [:]



    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Scanning
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        centralManager.scanForPeripherals(withServices: [sensorServiceUUID], options: nil)
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }

    // MARK: - Connection
    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    func disconnect() {
        if let p = connectedPeripheral {
            print("🔌 Disconnecting from peripheral: \(p.name ?? "Unknown")")
            print("📱 Available MACs: \(peripheralMACs)")
            // Immediately clear connection state for UI responsiveness
            connectedPeripheral = nil
            deviceSerial = nil
            // Stop sampling if active
            stopSampling()
            // Remove from discovered list immediately since device goes to sleep
            discoveredPeripherals.removeAll { $0.identifier == p.identifier }
            // Cancel the peripheral connection
            centralManager.cancelPeripheralConnection(p)
        } else {
            print("⚠️ No peripheral to disconnect")
        }
    }

    // MARK: - Sampling
    func startSampling() {
        temperatureData.removeAll()
        coData.removeAll()
        temperatureTimestamps.removeAll()    // ← clear old temps
        coTimestamps.removeAll()             // ← clear old COs
        isSampling = true
    }
    func stopSampling() {
        isSampling = false
    }
    
    private func timerDocRef(forMAC mac: String) -> DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("deviceTimers")
            .document(mac)
    }


    // MARK: - Firestore Upload
    /// Uploads one temperature+CO reading, tagged by device MAC.
    /// Upload one temperature+CO reading into a per-MAC "readings" subcollection.
    func uploadSensorData(mac: String, temperature: Double, co: Double) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // 1) Reference the "readings" subcollection under the MAC-named doc
        let readingsRef = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sensorData")
            .document(mac)               // one document per device
            .collection("readings")      // subcollection for all readings

        // 2) Auto-ID a new document for this single reading
        readingsRef.addDocument(data: [
            "timestamp": Timestamp(date: Date()),
            "temperature": temperature,
            "co": co
        ]) { error in
            if let e = error {
                print("Error uploading sensor data for \(mac):", e)
            }
        }
    }

}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        guard central.state == .poweredOn else {
            isScanning = false
            return
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
        
        // 2) extract 6-byte MAC from manufacturer data
        if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           mfgData.count >= 8
        {
          // company ID in bytes 0–1, MAC in bytes 2–7
          let macBytes = mfgData.subdata(in: 2..<8)
          let macString = macBytes
            .map { String(format: "%02X", $0) }
            .joined(separator: ":")
          DispatchQueue.main.async {
            self.peripheralMACs[peripheral.identifier] = macString
            print("📱 Stored MAC \(macString) for peripheral \(peripheral.name ?? "Unknown")")
          }
        }
    }
    // MARK: - CBCentralManagerDelegate

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        // Stop scanning once we've connected
        stopScanning()

        // Keep track of our connected peripheral
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([sensorServiceUUID, disServiceUUID])

        // Kick off live sampling immediately
        startSampling()

        // 1) Look up the MAC address we stored during discovery
        let uuid = peripheral.identifier
        guard let mac = peripheralMACs[uuid] else {
            print("⚠️  No MAC found for peripheral \(uuid)")
            return
        }

        // 2) ——— Firestore: listen for cumulative-duration updates ———
        if let doc = timerDocRef(forMAC: mac) {
            // Remove any old listener first
            timerListenersByMAC[mac]?.remove()

            let registration = doc.addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self,
                      let data = snapshot?.data() else { return }

                // Sync cumulative base
                self.cumulativeDurationsByMAC[mac] = data["cumulativeDuration"] as? TimeInterval ?? 0

                // Sync or initialize startTime
                if let ts = data["startTime"] as? Timestamp {
                    self.connectionStartDatesByMAC[mac] = ts.dateValue()
                } else {
                    self.connectionStartDatesByMAC[mac] = Date()
                }

                // Update published duration
                if let start = self.connectionStartDatesByMAC[mac] {
                    let base = self.cumulativeDurationsByMAC[mac] ?? 0
                    DispatchQueue.main.async {
                        self.connectionDurationsByMAC[mac] = base + Date().timeIntervalSince(start)
                    }
                }
            }

            // Store the listener so we can remove it on disconnect
            timerListenersByMAC[mac] = registration

            // Ensure a startTime exists in Firestore
            doc.getDocument { [weak self] snap, _ in
                guard let self = self,
                      snap?.data()?["startTime"] == nil else { return }
                let base = self.cumulativeDurationsByMAC[mac] ?? 0
                doc.setData([
                    "cumulativeDuration": base,
                    "startTime": FieldValue.serverTimestamp()
                ], merge: true)
            }
        }

        // 3) ——— Local timer fallback keyed by MAC ———
        connectionStartDatesByMAC[mac] = Date()
        connectionTimersByMAC[mac]?.invalidate()
        connectionTimersByMAC[mac] = Timer.scheduledTimer(withTimeInterval: 1.0,
                                                          repeats: true) { [weak self] _ in
            guard let self = self,
                  let start = self.connectionStartDatesByMAC[mac] else { return }
            let base = self.cumulativeDurationsByMAC[mac] ?? 0
            DispatchQueue.main.async {
                self.connectionDurationsByMAC[mac] = base + Date().timeIntervalSince(start)
            }
        }
    }



    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("🔌 Did disconnect peripheral: \(peripheral.name ?? "Unknown")")
        if let error = error {
            print("❌ Disconnect error: \(error.localizedDescription)")
        }
        
        // 1) Look up the MAC address we stored during discovery
        let uuid = peripheral.identifier
        guard let mac = peripheralMACs[uuid] else {
            print("⚠️  No MAC found for peripheral \(uuid)")
            return
        }

        // 2) ——— Remove Firestore listener keyed by MAC ———
        if let registration = timerListenersByMAC[mac] {
            registration.remove()
            timerListenersByMAC.removeValue(forKey: mac)
        }

        // 3) Clear connection state (only if not already cleared by disconnect())
        if connectedPeripheral == peripheral {
            deviceSerial = nil
            connectedPeripheral = nil
        }

        // 4) Remove from discovered list (only if not already removed by disconnect())
        discoveredPeripherals.removeAll { $0.identifier == uuid }

        // 5) Accumulate this session locally (MAC-keyed)
        if let start = connectionStartDatesByMAC[mac] {
            let base    = cumulativeDurationsByMAC[mac] ?? 0
            let session = Date().timeIntervalSince(start)
            let total   = base + session
            cumulativeDurationsByMAC[mac]   = total
            connectionDurationsByMAC[mac]   = total
        }

        // 6) Persist the final cumulativeDuration and clear startTime in Firestore
        if let doc = timerDocRef(forMAC: mac) {
            let total = cumulativeDurationsByMAC[mac] ?? 0
            doc.updateData([
                "cumulativeDuration": total,
                "startTime": FieldValue.delete()
            ])
        }

        // 7) Cleanup local timers keyed by MAC
        connectionTimersByMAC[mac]?.invalidate()
        connectionTimersByMAC.removeValue(forKey: mac)
        connectionStartDatesByMAC.removeValue(forKey: mac)
    }


}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        for service in peripheral.services ?? [] {
            switch service.uuid {
            case sensorServiceUUID:
                peripheral.discoverCharacteristics([
                    temperatureCharUUID,
                    coCharUUID
                ], for: service)

            case disServiceUUID:
                peripheral.discoverCharacteristics([serialNumberCharUUID], for: service)

            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
      guard error == nil else { return }
      for char in service.characteristics ?? [] {
        switch char.uuid {
        case coCharUUID where char.properties.contains(.notify):
          coCharacteristic = char
          peripheral.setNotifyValue(true, for: char)

        case temperatureCharUUID where char.properties.contains(.notify):
          temperatureCharacteristic = char
          peripheral.setNotifyValue(true, for: char)

        case serialNumberCharUUID where service.uuid == disServiceUUID:
          peripheral.readValue(for: char)

        default:
          break
        }
      }
    }


    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        
        guard error == nil, let data = characteristic.value else { return }
    
        // ① Always handle serial-number reads
        if characteristic.uuid == serialNumberCharUUID {
          let sn = String(data: data, encoding: .utf8) ?? "<bad-utf8>"
          DispatchQueue.main.async { self.deviceSerial = sn }
          return
        }


      switch characteristic.uuid {
      case coCharUUID:
        let c = parseCO(data)
          DispatchQueue.main.async {
              self.coData.append(c)
              self.coTimestamps.append(Date())     // ← record when CO arrived
          }

      case temperatureCharUUID:
        let t = parseTemperature(data)
          DispatchQueue.main.async {
              self.temperatureData.append(t)
              self.temperatureTimestamps.append(Date())
          }


      default:
        break
      }
    }

}

// MARK: - Data Parsing Helpers
private extension BLEManager {
    func parseTemperature(_ data: Data) -> Double {
        guard data.count >= 2 else { return 0 }
        let raw = Int((UInt16(data[1]) << 8) | UInt16(data[0]))
        return Double(raw) / 100.0
    }

    func parseCO(_ data: Data) -> Double {
        guard data.count >= 2 else { return 0 }
        let rawCO = Int((UInt16(data[0]) << 8) | UInt16(data[1]))
        return Double(rawCO)
    }
}

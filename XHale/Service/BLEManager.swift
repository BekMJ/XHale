import Foundation
import CoreBluetooth
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class BLEManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isScanning: Bool = false

    /// How long each device has been connected
    @Published var connectionDurations: [UUID: TimeInterval] = [:]

    // MARK: - Timing Storage
    private var cumulativeDurations: [UUID: TimeInterval] = [:]
    private var connectionStartDates: [UUID: Date] = [:]
    private var connectionTimers: [UUID: Timer] = [:]

    // MARK: - Sensor Data Arrays
    @Published var temperatureData: [Double] = []
    @Published var coData: [Double] = []
    @Published var deviceSerial: String?

    var isSampling = false
    @Published var coTimestamps: [Date] = []
    @Published var temperatureTimestamps: [Date] = []

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
    private var timerListeners: [UUID: ListenerRegistration] = [:]


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
            centralManager.cancelPeripheralConnection(p)
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
    
    // MARK: - Firestore Helpers
    private func timerDocRef(for id: UUID) -> DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("deviceTimers")
            .document(id.uuidString)
    }

    // MARK: - Firestore Upload
    func uploadSensorData(temperature: Double, co: Double) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sensorData")
            .document()
        let data: [String: Any] = [
            "timestamp": Timestamp(date: Date()),
            "temperature": temperature,
            "co": co
        ]
        doc.setData(data) { error in
            if let e = error {
                print("Error uploading sensor data: \(e)")
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([sensorServiceUUID, disServiceUUID])
        self.startSampling()

        let id = peripheral.identifier
        // Firestore: listen for updates
        if let doc = timerDocRef(for: id) {
            let registration = doc.addSnapshotListener { [weak self] snapshot, _ in
                guard let data = snapshot?.data(), let self = self else { return }
                // Sync cumulative base
                self.cumulativeDurations[id] = data["cumulativeDuration"] as? TimeInterval ?? 0
                // Sync startTime if exists, else mark now
                if let ts = data["startTime"] as? Timestamp {
                    self.connectionStartDates[id] = ts.dateValue()
                } else {
                    self.connectionStartDates[id] = Date()
                }
                // Update published duration
                if let start = self.connectionStartDates[id] {
                    let base = self.cumulativeDurations[id] ?? 0
                    self.connectionDurations[id] = base + Date().timeIntervalSince(start)
                }
            }
            timerListeners[id] = registration
            // Ensure startTime exists in Firestore
            doc.getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                if snap?.data()?["startTime"] == nil {
                    let base = self.cumulativeDurations[id] ?? 0
                    doc.setData([
                        "cumulativeDuration": base,
                        "startTime": FieldValue.serverTimestamp()
                    ], merge: true)
                }
            }
        }

        // Local timer
        connectionStartDates[id] = Date()
        connectionTimers[id]?.invalidate()
        connectionTimers[id] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.connectionStartDates[id] else { return }
            let base = self.cumulativeDurations[id] ?? 0
            self.connectionDurations[id] = base + Date().timeIntervalSince(start)
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
        
        let id = peripheral.identifier

        // ① remove Firestore listener
        if let registration = timerListeners[id] {
          registration.remove()
          timerListeners.removeValue(forKey: id)
        }
        if connectedPeripheral == peripheral {
            deviceSerial = nil   // ← clear it here
            connectedPeripheral = nil
        }
        
        discoveredPeripherals.removeAll { $0.identifier == peripheral.identifier }

        // Accumulate session
        if let start = connectionStartDates[id] {
            let base = cumulativeDurations[id] ?? 0
            let session = Date().timeIntervalSince(start)
            let total = base + session
            cumulativeDurations[id] = total
            connectionDurations[id] = total
        }
        // Firestore: write back and clear
        if let doc = timerDocRef(for: id) {
            let total = cumulativeDurations[id] ?? 0
            doc.updateData([
                "cumulativeDuration": total,
                "startTime": FieldValue.delete()
            ])
        }
        // Cleanup timers
        connectionTimers[id]?.invalidate()
        connectionTimers.removeValue(forKey: id)
        connectionStartDates.removeValue(forKey: id)
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

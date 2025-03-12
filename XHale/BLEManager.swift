//
//  BLEManager.swift
//  XHale
//
//  Created by YourName on Date.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isScanning: Bool = false
    
    // Sensor data arrays
    @Published var temperatureData: [Double] = []
    @Published var humidityData: [Double] = []
    @Published var pressureData: [Double] = []
    @Published var coData: [Double] = []
    
    var isSampling = false
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    
    // Replace with the actual UUIDs for your device.
    // This example assumes an Environmental Sensing service (0x181A)
    private let sensorServiceUUID  = CBUUID(string: "0000181a-0000-1000-8000-00805f9b34fb")
    private let temperatureCharUUID = CBUUID(string: "00002a6e-0000-1000-8000-00805f9b34fb")
    private let humidityCharUUID    = CBUUID(string: "00002a6f-0000-1000-8000-00805f9b34fb")
    private let pressureCharUUID    = CBUUID(string: "00002a6d-0000-1000-8000-00805f9b34fb")
    private let coCharUUID          = CBUUID(string: "00002bd0-0000-1000-8000-00805f9b34fb")
    
    override init() {
        super.init()
        // Initialize the CoreBluetooth central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        // Scan for the Environmental Sensing service (or your custom service)
        centralManager.scanForPeripherals(withServices: [sensorServiceUUID], options: nil)
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
    
    // MARK: - Connect
    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    func disconnect() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
    
    // MARK: - Sampling Control
       func startSampling() {
           // Clear old data
           temperatureData.removeAll()
           humidityData.removeAll()
           pressureData.removeAll()
           coData.removeAll()
           
           isSampling = true
       }
       
       func stopSampling() {
           isSampling = false
       }

}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is ON")
        default:
            print("Bluetooth is not available: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // Add discovered peripheral if not already in the list
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        
        // Stop scanning right away
        isScanning = false
        centralManager.stopScan()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        // Discover the Environmental Sensing service (or your custom service)
        peripheral.discoverServices([sensorServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown")")
        if connectedPeripheral == peripheral {
            connectedPeripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery error: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == sensorServiceUUID {
                // Discover the characteristics you need (Temp, Humidity, Pressure, CO)
                peripheral.discoverCharacteristics(
                    [temperatureCharUUID, humidityCharUUID, pressureCharUUID, coCharUUID],
                    for: service
                )
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error = error {
            print("Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // Subscribe to notifications if characteristic supports .notify
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            // Optionally read the initial value
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
    }		
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Update value error: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }
        
        guard isSampling else { return }
        
        // Parse data based on characteristic
        if characteristic.uuid == temperatureCharUUID {
            let temperature = parseTemperature(data)
            DispatchQueue.main.async {
                self.temperatureData.append(temperature)
            }
        } else if characteristic.uuid == humidityCharUUID {
            let humidity = parseHumidity(data)
            DispatchQueue.main.async {
                self.humidityData.append(humidity)
            }
        } else if characteristic.uuid == pressureCharUUID {
            let pressure = parsePressure(data)
            DispatchQueue.main.async {
                self.pressureData.append(pressure)
            }
        } else if characteristic.uuid == coCharUUID {
            let coValue = parseCO(data)
            DispatchQueue.main.async {
                self.coData.append(coValue)
            }
        }
    }
}

// MARK: - Data Parsing
private extension BLEManager {
    /// Parses a 2-byte little-endian temperature value in hundredths of a degree.
    ///
    /// Equivalent to your Android `convertTemperature()`:
    ///   int rawTemperature = ((rawData[1] & 0xFF) << 8) | (rawData[0] & 0xFF);
    ///   return rawTemperature / 100.0f;
    func parseTemperature(_ data: Data) -> Double {
        guard data.count >= 2 else { return 0 }
        let rawTemperature = Int((UInt16(data[1]) << 8) | UInt16(data[0]))
        return Double(rawTemperature) / 100.0
    }

    /// Parses a 2-byte little-endian humidity value in hundredths of a percent.
    ///
    /// Equivalent to your Android `convertHumidity()`:
    ///   int rawHumidity = ((rawData[1] & 0xFF) << 8) | (rawData[0] & 0xFF);
    ///   return rawHumidity / 100.0f;
    func parseHumidity(_ data: Data) -> Double {
        guard data.count >= 2 else { return 0 }
        let rawHumidity = Int((UInt16(data[1]) << 8) | UInt16(data[0]))
        return Double(rawHumidity) / 100.0
    }

    /// Parses a 4-byte little-endian pressure value, then divides by 10.
    ///
    /// Equivalent to your Android `convertPressure()`:
    ///   long rawPressure = ((rawData[3] & 0xFF) << 24)
    ///                    | ((rawData[2] & 0xFF) << 16)
    ///                    | ((rawData[1] & 0xFF) << 8)
    ///                    | (rawData[0] & 0xFF);
    ///   return rawPressure / 10.0f;
    func parsePressure(_ data: Data) -> Double {
        guard data.count >= 4 else { return 0 }
        let rawPressure =
            (UInt32(data[3]) << 24) |
            (UInt32(data[2]) << 16) |
            (UInt32(data[1]) << 8)  |
             UInt32(data[0])
        return Double(rawPressure) / 10.0
    }

    /// Parses a 2-byte big-endian CO value, applies slope/intercept, clamps to >= 0, then rounds.
    ///
    /// Equivalent to your Android `convertCOConcentration()`:
    ///   int rawCO = ((rawData[0] & 0xFF) << 8) | (rawData[1] & 0xFF);
    ///   double slope = 2.21;
    ///   double intercept = 4.52222222;
    ///   double calibratedCO = slope * rawCO + intercept;
    ///   if (calibratedCO < 0) { return 0; }
    ///   return (int) Math.round(calibratedCO);
    func parseCO(_ data: Data) -> Double {
        guard data.count >= 2 else { return 0 }
        
        // rawData[0] is high byte, rawData[1] is low byte
        let rawCO = Int((UInt16(data[0]) << 8) | UInt16(data[1]))
        
        // Same slope & intercept as Android
        let slope = 2.21
        let intercept = 4.52222222
        
        var calibratedCO = slope * Double(rawCO) + intercept
        if calibratedCO < 0 {
            calibratedCO = 0
        }
        
        // Return the rounded value as a Double
        return Double(Int(round(calibratedCO)))
    }

}

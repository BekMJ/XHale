//
//  CSVExporter.swift
//  XHale
//
//  Created by YourName on Date.
//

import SwiftUI

/// Creates a CSV file containing the 15-second sample data.
/// Returns a URL to the temporary file, or nil if something failed.
func createCSVFile(temperatureData: [Double],
                   humidityData: [Double],
                   pressureData: [Double],
                   coData: [Double]) -> URL? {
    
    // Build the CSV content
    var csvText = "Index,Temperature,Humidity,Pressure,CO\n"
    
    // Determine how many rows we need. Use the largest array size
    let maxCount = max(temperatureData.count,
                       humidityData.count,
                       pressureData.count,
                       coData.count)
    
    for i in 0..<maxCount {
        let temp = i < temperatureData.count ? temperatureData[i] : 0
        let hum  = i < humidityData.count ? humidityData[i] : 0
        let pres = i < pressureData.count  ? pressureData[i] : 0
        let co   = i < coData.count        ? coData[i] : 0
        
        csvText += "\(i),\(temp),\(hum),\(pres),\(co)\n"
    }
    
    // Write to a temporary file
    let fileName = "BreathSample.csv"
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(fileName)
    
    do {
        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    } catch {
        print("Error writing CSV: \(error)")
        return nil
    }
}

/// A SwiftUI wrapper for UIActivityViewController to share the CSV file.
struct CSVShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

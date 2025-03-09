//
//  XHaleApp.swift
//  XHale
//
//  Created by NPL-Weng on 3/7/25.
//

import SwiftUI

@main
struct XHaleApp: App {
    @StateObject private var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
            }
            .environmentObject(bleManager)
        }
    }
}



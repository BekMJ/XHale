import SwiftUI

struct SettingsView: View {
    @AppStorage("enableDarkMode") private var enableDarkMode: Bool = false
    @AppStorage("sampleDuration") private var sampleDuration: Int = 15
    @AppStorage("username") private var username: String = ""

    var body: some View {
        ZStack {
            // 1) Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            // 2) The settings form
            Form {
                Section(header: Text("Account")) {
                    TextField("Username", text: $username)
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                }
                
                Section(header: Text("Sampling")) {
                    Stepper("Duration: \(sampleDuration) s", value: $sampleDuration, in: 5...60)
                }	    	
            }
            // Make form background transparent on iOS 16+
            .scrollContentBackground(.hidden)
            // Fallback for older iOS: set the form’s background
            .background(Color.clear)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
    }
}



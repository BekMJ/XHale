import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
        }
        .navigationTitle("Notification Settings")
    }
}

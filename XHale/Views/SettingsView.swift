import SwiftUI
import FirebaseAuth
import UserNotifications   // ← Needed to request/revoke notification permissions

struct SettingsView: View {
    
    // MARK: – Stored Properties
    
    @AppStorage("enableDarkMode") private var enableDarkMode: Bool = false
    @AppStorage("sampleDuration") private var sampleDuration: Int = 15
    @AppStorage("username") private var username: String = ""
    @AppStorage("tutorialEnabled") private var tutorialEnabled: Bool = true
    
    // Battery management
    @AppStorage("batteryStartTime") private var batteryStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("lastBatteryReplacement") private var lastBatteryReplacement: Double = Date().timeIntervalSince1970
    
    @EnvironmentObject var tutorial: TutorialManager
    @EnvironmentObject var session: SessionStore
    
    // Track local toggle for notifications (AppStorage isn't ideal for permission state,
    // but we'll persist this flag and also check/update real UNAuthorizationStatus)
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    // Used only to trigger navigation if you ever needed to send someone back to AuthView.
    // (Removed because "Log Out" was deleted.)
    // @State private var shouldNavigateToAuth = false
    
    @State private var showDeleteAlert = false
    @State private var deleteErrorMessage: String?
    @State private var deleteSuccessMessage: String?
    @State private var showBatteryReplacementAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: – View Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            Form {
                // Tutorial Section
                Section(header: Text("Tutorial")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    Toggle("Show Tutorial on Launch", isOn: $tutorialEnabled)
                        .font(.body)
                        .foregroundColor(.primary)
                        .onChange(of: tutorialEnabled) { newValue in
                            // Persisted automatically via @AppStorage;
                            // you could enable/disable tutorial startup logic elsewhere.
                        }
                    Button("Run Tutorial Now") {
                        tutorial.currentIndex = 0
                        tutorial.isActive = true
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    .disabled(!tutorialEnabled)
                }
                // Appearance Section
                Section(header: Text("Appearance")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                        .font(.body)
                        .foregroundColor(.primary)
                        .onChange(of: enableDarkMode) { _ in
                            // This view (and all descendant views) will immediately adopt the new scheme
                            // because we apply .preferredColorScheme below.
                        }
                }
                // Device Section
                Section(header: Text("Device")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    HStack {
                        Text("Battery Status")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        BatteryIconView(startTime: batteryStartTime)
                    }
                    Button("Replace Battery") {
                        showBatteryReplacementAlert = true
                    }
                    .font(.body)
                    .foregroundColor(.orange)
                    .alert(isPresented: $showBatteryReplacementAlert) {
                        Alert(
                            title: Text("Replace Battery"),
                            message: Text("This will reset the battery timer. Only do this when you've actually replaced the device battery."),
                            primaryButton: .default(Text("Replace")) {
                                replaceBattery()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                // Sampling Section
                Section(header: Text("Sampling")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    Stepper("Duration: \(sampleDuration) s", value: $sampleDuration, in: 5...60)
                        .font(.body)
                        .foregroundColor(.primary)
                        .onChange(of: sampleDuration) { newDuration in
                            // Persisted automatically via @AppStorage.
                            // If you need extra logic (e.g. restart a timer), do it here.
                        }
                }
                // Privacy & Security Section
                Section(header: Text("Privacy & Security")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                        .font(.body)
                        .foregroundColor(.primary)
                    NavigationLink("Terms of Service", destination: TermsOfServiceView())
                        .font(.body)
                        .foregroundColor(.primary)
                }
                // About Section
                Section(header: Text("About")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    HStack {
                        Text("App Version")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(currentAppVersion())")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                // Account Section (moved to bottom, username removed)
                Section(header: Text("Account")
                    .font(.headline)
                    .foregroundColor(.primary)) {
                    NavigationLink("Update Password", destination: UpdatePasswordView())
                        .font(.body)
                        .foregroundColor(.primary)
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete Account")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Delete Account"),
                            message: Text("Are you sure you want to permanently delete your account? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteAccount()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    if let deleteErrorMessage = deleteErrorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                            Text(deleteErrorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .accessibilityLabel("Error: \(deleteErrorMessage)")
                        }
                    }
                    if let deleteSuccessMessage = deleteSuccessMessage {
                        Text(deleteSuccessMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Button(action: { session.signOut() }) {
                        Text("Log Out")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        // Force the entire SettingsView to respect the "Dark Mode" toggle:
        .preferredColorScheme(enableDarkMode ? .dark : .light)
    }
    
    // MARK: – Helper Methods
    
    private func requestNotificationPermission() {
        // Ask the user for notification authorization if not already granted
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                // Already authorized; nothing more to do
                break
            case .denied:
                // The user has explicitly denied—if you want to allow them to re-enable,
                // you could show an alert pointing them to Settings.app
                DispatchQueue.main.async {
                    notificationsEnabled = false
                }
            case .notDetermined:
                // Ask for permission
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        notificationsEnabled = granted
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    private func disableAllNotifications() {
        // When toggling OFF, remove pending notifications and/or badges as needed.
        // This simply removes all delivered/pending notifications.
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    private func currentAppVersion() -> String {
        // Fetch version from Info.plist (make sure CFBundleShortVersionString is set)
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0"
    }
    
    private func deleteAccount() {
        deleteErrorMessage = nil
        deleteSuccessMessage = nil
        if let user = Auth.auth().currentUser {
            user.delete { error in
                if let error = error {
                    deleteErrorMessage = error.localizedDescription
                } else {
                    deleteSuccessMessage = "Account deleted successfully."
                    // Optionally, navigate to login or close settings
                    // presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            deleteErrorMessage = "No user is currently signed in."
        }
    }
    
    private func replaceBattery() {
        let currentTime = Date().timeIntervalSince1970
        batteryStartTime = currentTime
        lastBatteryReplacement = currentTime
    }
}

// MARK: - Battery Icon View
struct BatteryIconView: View {
    let startTime: Double
    private let maxBatteryHours: Double = 170.0 // 170 hours max battery life
    
    private var batteryLevel: Double {
        let currentTime = Date().timeIntervalSince1970
        let elapsedHours = (currentTime - startTime) / 3600.0 // Convert seconds to hours
        let remainingHours = max(0, maxBatteryHours - elapsedHours)
        return min(1.0, remainingHours / maxBatteryHours)
    }
    
    private var batteryColor: Color {
        if batteryLevel > 0.5 {
            return .green
        } else if batteryLevel > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var batteryIcon: String {
        if batteryLevel > 0.8 {
            return "battery.100"
        } else if batteryLevel > 0.6 {
            return "battery.75"
        } else if batteryLevel > 0.4 {
            return "battery.50"
        } else if batteryLevel > 0.2 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIcon)
                .foregroundColor(batteryColor)
            Text("\(Int(batteryLevel * 100))%")
                .font(.caption)
                .foregroundColor(batteryColor)
        }
    }
}

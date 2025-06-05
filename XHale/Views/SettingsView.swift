import SwiftUI
import FirebaseAuth
import UserNotifications   // ← Needed to request/revoke notification permissions

struct SettingsView: View {
    
    // MARK: – Stored Properties
    
    @AppStorage("enableDarkMode") private var enableDarkMode: Bool = false
    @AppStorage("sampleDuration") private var sampleDuration: Int = 15
    @AppStorage("username") private var username: String = ""
    @AppStorage("tutorialEnabled") private var tutorialEnabled: Bool = true
    
    @EnvironmentObject var tutorial: TutorialManager
    
    // Track local toggle for notifications (AppStorage isn’t ideal for permission state,
    // but we’ll persist this flag and also check/update real UNAuthorizationStatus)
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    // Used only to trigger navigation if you ever needed to send someone back to AuthView.
    // (Removed because “Log Out” was deleted.)
    // @State private var shouldNavigateToAuth = false
    
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
                // Account Section (no Log Out button anymore)
                Section(header: Text("Account")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    NavigationLink("Update Password", destination: UpdatePasswordView())
                }
                
                // Tutorial Section
                Section(header: Text("Tutorial")) {
                    Toggle("Show Tutorial on Launch", isOn: $tutorialEnabled)
                        .onChange(of: tutorialEnabled) { newValue in
                            // Persisted automatically via @AppStorage;
                            // you could enable/disable tutorial startup logic elsewhere.
                        }
                    
                    Button("Run Tutorial Now") {
                        tutorial.currentIndex = 0
                        tutorial.isActive = true
                    }
                    .disabled(!tutorialEnabled)
                }
                
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                        .onChange(of: enableDarkMode) { _ in
                            // This view (and all descendant views) will immediately adopt the new scheme
                            // because we apply .preferredColorScheme below.
                        }
                    
                    NavigationLink("Theme Settings", destination: ThemeSettingsView())
                }
                
                // Sampling Section
                Section(header: Text("Sampling")) {
                    Stepper("Duration: \(sampleDuration) s", value: $sampleDuration, in: 5...60)
                        .onChange(of: sampleDuration) { newDuration in
                            // Persisted automatically via @AppStorage.
                            // If you need extra logic (e.g. restart a timer), do it here.
                        }
                }
                
                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                disableAllNotifications()
                            }
                        }
                    
                    NavigationLink("Notification Settings", destination: NotificationSettingsView())
                }
                
                // Privacy & Security Section
                Section(header: Text("Privacy & Security")) {
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    NavigationLink("Terms of Service", destination: TermsOfServiceView())
                    NavigationLink("Data Backup & Export", destination: DataBackupView())
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("\(currentAppVersion())")
                            .foregroundColor(.gray)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        // Force the entire SettingsView to respect the “Dark Mode” toggle:
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
}

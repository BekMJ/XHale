import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("enableDarkMode") private var enableDarkMode: Bool = false
    @AppStorage("sampleDuration") private var sampleDuration: Int = 15
    @AppStorage("username") private var username: String = ""
    @AppStorage("tutorialEnabled") private var tutorialEnabled: Bool = true
    
    @EnvironmentObject var tutorial: TutorialManager
    
    @State private var notificationsEnabled: Bool = true
    @State private var shouldNavigateToAuth = false
    

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
                // Account Section
                Section(header: Text("Account")) {
                    TextField("Username", text: $username)
                    NavigationLink("Update Password", destination: UpdatePasswordView())
                     
                    // Log Out Button
                    Button("Log Out") {
                        signOut()
                    }
                    .foregroundColor(.red)
                    
                    // NavigationLink to AuthView for sign-out
                    NavigationLink(
                        destination: AuthView(),
                        isActive: $shouldNavigateToAuth,
                        label: { EmptyView() }
                    )
                }
                Section(header: Text("Tutorial")) {
                    Toggle("Show Tutorial on Launch", isOn: $tutorialEnabled)

                    Button("Run Tutorial Now") {
                        // reset & start immediately
                        tutorial.currentIndex = 0
                        tutorial.isActive = true
                    }
                    .disabled(!tutorialEnabled)  // optional: only if they’ve enabled it
                }
                
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                    NavigationLink("Theme Settings", destination: ThemeSettingsView())
                }
                
                // Sampling Section
                Section(header: Text("Sampling")) {
                    Stepper("Duration: \(sampleDuration) s", value: $sampleDuration, in: 5...60)
                }
                
                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
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
                        Text("1.0.0").foregroundColor(.gray)
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
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            withAnimation(.easeInOut(duration: 0.3)) {
                shouldNavigateToAuth = true
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

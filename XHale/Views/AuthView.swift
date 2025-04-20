import SwiftUI
import Firebase
import FirebaseAuth

struct AuthView: View {
    enum AuthMode {
        case login, register
    }
    
    // ← Add this
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    @State private var authMode: AuthMode = .login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoggedIn: Bool = false
    
    // Using AppStorage for demonstration; consider Keychain for production.
    @AppStorage("rememberPassword") private var rememberPassword: Bool = false
    @AppStorage("savedEmail") private var savedEmail: String = ""
    @AppStorage("savedPassword") private var savedPassword: String = ""
    
    var body: some View {
        ZStack {
            // Static gradient background remains unchanged.
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // ← New: offline overlay
            if !networkMonitor.isConnected {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    Text("No Internet Connection")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    Text("Please connect to Wi‑Fi or cellular data to continue.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    Button("Retry") {
                        // NWPathMonitor will re‑fire when connectivity changes
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
            else if isLoggedIn || Auth.auth().currentUser != nil {
                HomeView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // ← Your existing login/register UI
                VStack(spacing: 24) {
                    Image("Image")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding(.top, 40)
                    
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Picker(selection: $authMode, label: Text("Authentication Mode")) {
                        Text("Login").tag(AuthMode.login)
                        Text("Register").tag(AuthMode.register)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "envelope").foregroundColor(.gray)
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        HStack {
                            Image(systemName: "lock").foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        Toggle("Remember Password", isOn: $rememberPassword)
                            .padding(.horizontal)
                            .foregroundColor(.white)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage).foregroundColor(.red)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if authMode == .login { login() }
                                else { register() }
                            }
                        }) {
                            Text(authMode == .login ? "Login" : "Register")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(authMode == .login ? Color.blue : Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    Button("Forgot Password?") {
                        // Implement forgot password flow here
                    }
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.footnote)
                }
                .onAppear {
                    if rememberPassword {
                        email = savedEmail
                        password = savedPassword
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
    }
    
    // MARK: - Firebase Authentication Methods
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                if rememberPassword {
                    savedEmail = email
                    savedPassword = password
                } else {
                    savedEmail = ""
                    savedPassword = ""
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoggedIn = true
                }
            }
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                if rememberPassword {
                    savedEmail = email
                    savedPassword = password
                } else {
                    savedEmail = ""
                    savedPassword = ""
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoggedIn = true
                }
            }
        }
    }
}

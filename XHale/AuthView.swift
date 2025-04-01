import SwiftUI
import Firebase
import FirebaseAuth

struct AuthView: View {
    enum AuthMode {
        case login, register
    }
    
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
            
            if isLoggedIn || Auth.auth().currentUser != nil {
                HomeView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 24) {
                    // Logo (if available)
                    Image("Image")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding(.top, 40)
                    
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Toggle between Login and Register modes
                    Picker(selection: $authMode, label: Text("Authentication Mode")) {
                        Text("Login").tag(AuthMode.login)
                        Text("Register").tag(AuthMode.register)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    
                    // Login/Register Card with white background
                    VStack(spacing: 16) {
                        // Email field with icon
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .foregroundColor(.black)  // Dark text for email
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        // Password field with icon
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .foregroundColor(.black)  // Dark text for password
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        // Remember Password toggle (label in white)
                        Toggle("Remember Password", isOn: $rememberPassword)
                            .padding(.horizontal)
                            .foregroundColor(.white)
                        
                        // Display error message if available
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        
                        // Login or Register button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if authMode == .login {
                                    login()
                                } else {
                                    register()
                                }
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
                    
                    // Forgot password link
                    Button("Forgot Password?") {
                        // Implement forgot password flow here
                    }
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.footnote)
                }
                .onAppear {
                    // Auto-fill if remember password is enabled
                    if rememberPassword {
                        email = savedEmail
                        password = savedPassword
                    }
                }
            }
        }
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

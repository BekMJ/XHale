import SwiftUI
import FirebaseAuth

struct UpdatePasswordView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    var isPasswordValid: Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$")
        return passwordTest.evaluate(with: newPassword)
    }
    
    var canUpdate: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        isPasswordValid &&
        !isLoading
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                if showNewPassword {
                    TextField("New Password", text: $newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("New Password", text: $newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                HStack {
                    Spacer()
                    Button(action: { showNewPassword.toggle() }) {
                        Image(systemName: showNewPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 12)
                }
            )
            
            Group {
                if showConfirmPassword {
                    TextField("Confirm Password", text: $confirmPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                HStack {
                    Spacer()
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 12)
                }
            )
            
            if !newPassword.isEmpty && !isPasswordValid {
                Text("Password must be at least 8 characters, include at least one letter and one number.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .accessibilityLabel("Error: \(errorMessage)")
                }
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
            }
            
            Button(action: {
                updatePassword()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Update Password")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(canUpdate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(!canUpdate)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Update Password")
    }
    
    func updatePassword() {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                successMessage = "Password updated successfully."
                errorMessage = nil
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
}

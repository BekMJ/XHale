import SwiftUI
import FirebaseAuth

struct UpdatePasswordView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            SecureField("New Password", text: $newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
            }
            
            Button("Update Password") {
                updatePassword()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Update Password")
    }
    
    func updatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                successMessage = "Password updated successfully."
                errorMessage = nil
            }
        }
    }
}

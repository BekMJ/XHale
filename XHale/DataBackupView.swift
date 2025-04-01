import SwiftUI

struct DataBackupView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Data Backup & Export")
                .font(.title)
            
            Button("Export Data as CSV") {
                // Trigger your CSV export functionality here.
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Data Backup & Export")
    }
}

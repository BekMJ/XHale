import SwiftUI

struct InstructionView: View {
    // Controls whether the side menu is visible
    @State private var isShowingMenu = false
    
    // Width of the side menu
    private let menuWidth: CGFloat = 250
    var body: some View {
        // ZStack so we can layer the menu behind the main content
            ZStack {
                // 1) Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                
                
                // 2) Main content
                VStack(spacing: 8) {
                    
                    
                    Text("How to Use the Device")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Image("device")  // Name in Assets.xcassets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250) // Adjust as needed
                        .shadow(radius: 8)
                    
                    // Instruction box with bullet points or paragraphs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Press the reset button located on the front of the device before starting to scan")
                        Text("• The device is named Univ. Okla")
                        Text("• Keep the device within Bluetooth range.")
                        Text("• Once connected to your phone, you can start receiving the data")
                        Text("• When using the breath sample make sure to breathe deeply into the device for 15 seconds")
                        Text("Notice that the device does not have power off button, therefore just press disconnect button and the device will automatically turn off")
                        
                        
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // You can add more instructions or images here
                    // For example, an image of the device, or a step-by-step diagram
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
        
    }
}



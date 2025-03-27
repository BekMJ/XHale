import SwiftUI
import UIKit
import SceneKit

struct InstructionView: View {
    @State private var isShowingMenu = false
    private let menuWidth: CGFloat = 250
    
    var body: some View {
        ZStack {
            // 1) Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // 2) Main content wrapped in a scroll view
            ScrollView {
                VStack(spacing: 8) {
                    Text("How to Use the Device")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Image("device")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .shadow(radius: 8)
                    
                    TransparentSceneView()
                        .frame(width: 300, height: 300)
                    
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
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Instructions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
    }
}


struct TransparentSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // Load the 3D scene from your device3d.scn file
        guard let scene = SCNScene(named: "device3d.scn") else {
            fatalError("Failed to load device3d.scn")
        }
        sceneView.scene = scene

        // Enable camera control so the user can override the auto rotation
        sceneView.allowsCameraControl = true
        
        // Make the background transparent
        sceneView.backgroundColor = .clear
        
        // Automatically add default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // Auto-rotate the model node
        // Adjust the node name ("model") to match your scene's hierarchy.
        if let modelNode = scene.rootNode.childNode(withName: "model", recursively: true) {
            let rotationAction = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat(2 * .pi), z: 0, duration: 10)
            )
            modelNode.runAction(rotationAction)
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}


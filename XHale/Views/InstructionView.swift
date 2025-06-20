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
                VStack(spacing: 2) {
                    Text("How to Use the Device")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityLabel("How to Use the Device")
                    TransparentView()
                        .frame(width: 350, height: 350)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Press the reset button located on the front of the device before starting to scan")
                        Text("• The Bluetooth device is named XHale")
                        Text("• Keep the device within Bluetooth range.")
                        Text("• Once connected to your phone, you can start receiving the data")
                        Text("• When using the breath sample make sure to breathe deeply into the device for 15 seconds")
                        Text("Notice that the device does not have power off button, therefore just press disconnect button and the device will automatically turn off")
                    }
                    .font(.body)
                    .foregroundColor(.primary)
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



struct TransparentView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        // Instantiate our custom SCNView.
        let sceneView = CustomSCNView(frame: .zero)
        
        // Load your scene file (e.g., "CO6.scn")
        guard let scene = SCNScene(named: "CO6.scn") else {
            fatalError("Failed to load scene 'CO6.scn'")
        }
        sceneView.scene = scene
        
        // Enable free camera control for user interaction.
        sceneView.allowsCameraControl = true
        
        // Enable default lighting and set background to transparent.
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        
        // Configure a custom camera to "zoom in" by positioning it closer.
        // If the scene doesn't have a camera, create one.
        if scene.rootNode.childNodes.filter({ $0.camera != nil }).isEmpty {
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            // Adjust the camera's fieldOfView as needed.
            // Option 1: Alter fieldOfView (smaller value = zoomed in).
            // cameraNode.camera?.fieldOfView = 40
            // Option 2: Position the camera closer along the z-axis.
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
            scene.rootNode.addChildNode(cameraNode)
            sceneView.pointOfView = cameraNode
        } else {
            // If there's an existing camera, adjust its position.
            if let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
                cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
                sceneView.pointOfView = cameraNode
            }
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the view if needed.
    }
}




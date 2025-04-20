import SceneKit
import UIKit

class CustomSCNView: SCNView {
    var containerNode: SCNNode?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let scene = self.scene else { return }
        
        // Locate the model node by its name ("CO")
        if let modelNode = scene.rootNode.childNode(withName: "CO", recursively: true) {
            // Calculate the center of the model's bounding box
            let (minVec, maxVec) = modelNode.boundingBox
            let center = SCNVector3(
                (minVec.x + maxVec.x) / 2,
                (minVec.y + maxVec.y) / 2,
                (minVec.z + maxVec.z) / 2
            )
            
            // Create a container node positioned at the center of mass
            let container = SCNNode()
            container.position = center
            
            // Reposition the model so that its center aligns with the container's origin
            modelNode.position = SCNVector3(-center.x, -center.y, -center.z)
            
            // Remove the model from its original parent and add it to the container
            modelNode.removeFromParentNode()
            container.addChildNode(modelNode)
            
            // Add the container node to the scene's root node
            scene.rootNode.addChildNode(container)
            containerNode = container
            
            // >>> Add these lines to recenter the container in the scene <<<
            let (cMin, cMax) = container.boundingBox
            let containerCenter = SCNVector3(
                (cMin.x + cMax.x) / 2,
                (cMin.y + cMax.y) / 2,
                (cMin.z + cMax.z) / 2
            )
            container.pivot = SCNMatrix4MakeTranslation(containerCenter.x, containerCenter.y, containerCenter.z)
            container.position = SCNVector3Zero
        }
    }
    
    // All touch handlers have been left unmodified, so the built-in camera controls remain active.
}

//
//  ViewController.swift
//  ARImageFinder
//
//  Created by Mark Meretzky on 1/21/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;
import SceneKit;
import ARKit;

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!;   //already contains a SCNScene
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Set the view's delegate.
        sceneView.delegate = self;
        
        // Show statistics such as fps and timing information.
        sceneView.showsStatistics = true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        guard let referenceImages: Set<ARReferenceImage> = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("could not get reference images");
        }
        
        // Create a session configuration.
        let configuration: ARWorldTrackingConfiguration = ARWorldTrackingConfiguration();
        configuration.detectionImages = referenceImages;

        // Run the view's session.
        sceneView.session.run(configuration);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        // Pause the view's session
        sceneView.session.pause();
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor: ARImageAnchor = anchor as? ARImageAnchor else {
            return;   //interested only in ARImageAnchors
        }
        
        let referenceImage: ARReferenceImage = imageAnchor.referenceImage;
        let size: CGSize = referenceImage.physicalSize;
        
        //Get the position of the image's anchor.
        let column3: simd_float4 = imageAnchor.transform.columns.3;
        let position: SCNVector3 = SCNVector3(column3.x, column3.y, column3.z);
        
        let imageName: String = referenceImage.name ?? "<no name>";
        print(String(format: "Discovered new image named %@ of size %.2f × %.2f at position (%.2f, %.2f, %.2f).", imageName, size.width, size.height, position.x, position.y, position.z));

        let plane: SCNPlane = SCNPlane(width: size.width, height: size.height);
        if let firstMaterial: SCNMaterial = plane.firstMaterial {
            firstMaterial.diffuse.contents = UIColor.blue;
        } else {
            fatalError("SCNPlane had no firstMaterial");
        }

        //Create, configure, and attach the new node.

        let planeNode: SCNNode = SCNNode(geometry: plane);
        planeNode.eulerAngles.x = -.pi / 2;
        planeNode.opacity = 0.25;
        node.addChildNode(planeNode);
        
        //Schedule the new node to be detached after 5 seconds.
        //First, create an array of SCNAction objects.

        let arrayOfActions: [SCNAction] = [
            .wait(duration: 5.0),
            .fadeOut(duration: 2.0),
            .removeFromParentNode() //Remove the planeNode from its parent, the empty node.
        ];
        
        //Combine the array into one big SCNAction object.
        
        let oneBigAction: SCNAction = .sequence(arrayOfActions);
        
        //Execute all the actions in the one big object.
        //When it's done, execute the closure in {curly braces}.

        planeNode.runAction(oneBigAction) {
            print("\(imageName) has been removed.");
            //If we want to recognize the image a second time,
            self.sceneView.session.remove(anchor: imageAnchor);
        }
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node: SCNNode = SCNNode();
        return node;
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

//
//  ViewController.swift
//  Impuls_iOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import UIKit
import CoreLocation
import AudioKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    var sceneLocationView = ARSCNView()
    let configuration = ARWorldTrackingConfiguration()
    
    let audioService = AudioService()
    let numNodes = 5
    
    var interactionDistance = 0.2
    
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    
    var nodes = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneLocationView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        // 2
        sceneLocationView.session.run(configuration)
        view.addSubview(sceneLocationView)
        
        sceneLocationView.session.delegate = self
        audioService.delegate = self
    
        AKSettings.playbackWhileMuted = true
        AKSettings.useBluetooth = true
        
        for i in 0 ..< numNodes {
            oscillators.append(AKOscillator())
            oscillators[i].frequency = 220 + i*220
            oscillators[i].amplitude = 0
            oscillators[i] >>> mixer
        }
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        for osc in oscillators {
            osc.start()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = view.bounds
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        for i in 0 ..< numNodes {
            let node = addShape(x: -0.5 + (i * 0.25), y: -0.1, z: -0.3 + abs(2 - i)*0.1, radius: 0.05)
            nodes.append(node)
        }
        
    }
    
    
    func addShape(x: Double, y: Double, z: Double, radius: CGFloat) -> SCNNode {
        let node = SCNNode()
        node.geometry = SCNCylinder(radius: radius, height: 2)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        node.position = SCNVector3(x, y, z)
        
        DispatchQueue.main.async {
            self.sceneLocationView.scene.rootNode.addChildNode(node)
        }
        
        return node
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
        let cameraPosition = frame.camera.transform.columns.3
        let node1Position = nodes[0].simdTransform.columns.3
        let node2Position = nodes[1].simdTransform.columns.3
        let node3Position = nodes[2].simdTransform.columns.3
        let node4Position = nodes[3].simdTransform.columns.3
        let node5Position = nodes[4].simdTransform.columns.3
        
        // here’s a line connecting the two points, which might be useful for other things
        let cameraToNode1 = cameraPosition - node1Position
        let cameraToNode2 = cameraPosition - node2Position
        let cameraToNode3 = cameraPosition - node3Position
        let cameraToNode4 = cameraPosition - node4Position
        let cameraToNode5 = cameraPosition - node5Position
        // and here’s just the scalar distance
        let distance1 = length(cameraToNode1)
        let distance2 = length(cameraToNode2)
        let distance3 = length(cameraToNode3)
        let distance4 = length(cameraToNode4)
        let distance5 = length(cameraToNode5)
        
        //print("1 - \(distance1)")
        //print("2 - \(distance2)")
        
        oscillators[0].amplitude = Double(1 - (abs(distance1)/interactionDistance))
        oscillators[1].amplitude = Double(1 - (abs(distance2)/interactionDistance))
        oscillators[2].amplitude = Double(1 - (abs(distance3)/interactionDistance))
        oscillators[3].amplitude = Double(1 - (abs(distance4)/interactionDistance))
        oscillators[4].amplitude = Double(1 - (abs(distance5)/interactionDistance))
        
        audioService.send(distance: "a" + String(distance1) + " " + "\(audioService.myPeerId)")
        audioService.send(distance: "b" + String(distance2) + " " + "\(audioService.myPeerId)")
    }
    
    
  
}

extension ViewController : AudioServiceDelegate {
    
    func connectedDevicesChanged(manager: AudioService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            print(connectedDevices)
        }
    }
    
    func distanceChanged(manager: AudioService, distance: String) {
        OperationQueue.main.addOperation {
            print(distance)
        }
    }
    
}

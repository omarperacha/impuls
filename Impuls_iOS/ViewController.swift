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
    
    let latOsc = AKOscillator()
    let lonOsc = AKOscillator()
    var mixer = AKMixer()
    
    var node1 : SCNNode?
    var node2 : SCNNode?
    
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
        
        latOsc.frequency = 440
        lonOsc.frequency = 660
        mixer = AKMixer(latOsc, lonOsc)
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        latOsc.start()
        lonOsc.start()
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
        

        node1 = addShape(x: 0, y: -0.3, z: -8)
        node2 = addShape(x: -2, y: -0.3, z: -4)
        
        
    }
    
    
    func addShape(x: Double, y: Double, z: Double) -> SCNNode {
        let node = SCNNode()
        node.geometry = SCNSphere(radius: 0.2)
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
        let node1Position = node1?.simdTransform.columns.3
        let node2Position = node2?.simdTransform.columns.3
        
        // here’s a line connecting the two points, which might be useful for other things
        let cameraToNode1 = cameraPosition - node1Position!
        let cameraToNode2 = cameraPosition - node2Position! 
        // and here’s just the scalar distance
        let distance1 = length(cameraToNode1)
        let distance2 = length(cameraToNode2)
        
        //print("1 - \(distance1)")
        //print("2 - \(distance2)")
        
        lonOsc.amplitude = Double(1 - (abs(distance1)/4))
        latOsc.amplitude = Double(1 - (abs(distance2)/4))
        
        audioService.send(distance: "a" + String(distance1))
        audioService.send(distance: "b" + String(distance2))
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

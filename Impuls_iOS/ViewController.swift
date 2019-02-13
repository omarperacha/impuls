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
        var nodePositions = [simd_float4]()
        var cameraToNodes = [simd_float4]()
        var distances = [Float]()
        for i in 0 ..< numNodes {
            nodePositions.append(nodes[i].simdTransform.columns.3)
            // here’s a line connecting the two points, which might be useful for other things
            cameraToNodes.append(cameraPosition - nodePositions[i])
            distances.append(length(cameraToNodes[i]))
            
            oscillators[i].amplitude = Double(1 - (abs(distances[i])/interactionDistance))
            
            audioService.send(distance: String(UnicodeScalar(i+97)!) + String(distances[i]) + " " + "\(audioService.myPeerId)")
            
        }
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

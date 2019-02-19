//
//  ViewController.swift
//  Impuls_iOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import UIKit
import AudioKit
import ARKit
import CoreMotion
import MediaPlayer

let conductor = AudioManager()

class ViewController: UIViewController, ARSessionDelegate {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
            
        }
    }
    
    var sceneLocationView = ARSCNView()
    private let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    
    let sceneConfig = "Outdoor"
    let sceneNodeDict = ["Sax" : 4, "Outdoor" : 5, "Column" : 1, "Conductor": 1]
    
    var audioService: AudioService!
    var numNodes = 0
    
    var distances = [Float]()
    
    var nodes = [SCNNode]()
    
    var roll = -180.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneLocationView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints
        ]
        // 2
        sceneLocationView.session.run(configuration)
        view.addSubview(sceneLocationView)
        
        if sceneConfig == "Column" {
            let button = UIButton(frame: CGRect(x: self.view.bounds.midX - 75, y: 500, width: 150, height: 100))
            button.backgroundColor = .cyan
            button.setTitle("Trigger", for: .normal)
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            
            self.sceneLocationView.addSubview(button)
        }
        
        let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 40, width: 300, height: 30))
        self.view.addSubview(volumeView)
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)),
                                               name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                               object: nil)
        volumeView.isHidden = true
        
        sceneLocationView.session.delegate = self
        
        if sceneConfig != "Sax" {
            audioService = AudioService()
            audioService.delegate = self
        }
    
        numNodes = sceneNodeDict[sceneConfig]!
        
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
        
        if sceneConfig == "Sax" {
            conductor.interactionDistance = 0.4
            for i in 0 ..< numNodes {
                let node = addShape(x: 0.0 + (i % 2) * (2-i) * 0.5, y: -0.1, z:  0.0 + ((i % 2) - 1) * (1 - i) * 0.5, radius: 0.05)
                nodes.append(node)
                distances.append(100.0)
            }
        } else if sceneConfig == "Outdoor" {
            conductor.interactionDistance = 1.5
            for i in 0 ..< (numNodes - 1) {
                let node = addShape(x: i % 2 == 0 ? -1 : 1, y: 0.5, z: i < 2 ? -2 : 2, radius: 0.2)
                nodes.append(node)
                distances.append(100.0)
            }
            
            let node = addShape(x: 0, y: -1, z: 0, radius: 0.2)
            nodes.append(node)
            distances.append(100.0)
            
        } else if sceneConfig == "Column" {
            conductor.interactionDistance = 0.4
            
            let node1 = addShape(x: 0, y: -0.1, z: -0.5, radius: 0.1)
            nodes.append(node1)
            
            for _ in 0 ..< numNodes {
                distances.append(100.0)
            }
            
            toggleFlash()
            
        }
        
         conductor.initialise(config: sceneConfig, nodes: numNodes)
        
        if motionManager.isDeviceMotionAvailable {
            
            motionManager.deviceMotionUpdateInterval = 0.1
            
            motionManager.startDeviceMotionUpdates(to: OperationQueue()) { (motion, error) -> Void in
                
                if let attitude = motion?.attitude {
                    self.roll = attitude.roll * 180 / Double.pi
                    self.sendSignalfromRoll()
                }
                
            }
            
            print("Device motion started")
        }
        else {
            print("Device motion unavailable")
        }
    }
    
    
    func addShape(x: Double, y: Double, z: Double, radius: CGFloat) -> SCNNode {
        let node = SCNNode()
        if sceneConfig == "Sax" {
            node.geometry = SCNCylinder(radius: radius, height: 2)
        } else {
            node.geometry = SCNSphere(radius: radius)
        }
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
        
        if numNodes == 0 {
            return
        }
        
        for i in 0 ..< numNodes {
            nodePositions.append(nodes[i].simdTransform.columns.3)
            // here’s a line connecting the two points, which might be useful for other things
            cameraToNodes.append(cameraPosition - nodePositions[i])
            distances[i] = length(cameraToNodes[i])
            
            conductor.updateSound(distance: distances[i], rollVal: roll, index: i)
            
            if audioService != nil {
                audioService.send(distance: String(UnicodeScalar(i+97)!) + String(distances[i]) + " " + String(roll) + " " + audioService.myPeerId.displayName)
            }
            
        }
    }
    
    func sendSignalfromRoll(){
        
        for i in 0 ..< numNodes {
            
            conductor.updateSound(distance: distances[i], rollVal: roll, index: i)
            
            if audioService != nil {
            audioService.send(distance: String(UnicodeScalar(i+97)!) + String(distances[i]) + " " + String(roll) + " " + audioService.myPeerId.displayName)
            }
            
        }
        
    }
    
    @objc func volumeChanged(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let volumeChangeType = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
                if volumeChangeType == "ExplicitVolumeChange" {
                    if audioService != nil {
                        audioService.send(distance: "0" + audioService.myPeerId.displayName)
                    }
                }
            }
        }
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        if audioService != nil {
            audioService.send(distance: "1" + audioService.myPeerId.displayName)
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

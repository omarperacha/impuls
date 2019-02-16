//
//  audioManager.swift
//  Impuls_iOS
//
//  Created by Omar Peracha on 16/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Foundation
import AudioKit

class AudioManager {
    
    private let lock = NSLock()
    var interactionDistance = 0.4
    private var nodes = 0
    private var config = "none"
    
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    
    
    func initialise(config: String, nodes: Int){
        lock.lock()
        defer {
            lock.unlock()
        }
        
        AKSettings.playbackWhileMuted = true
        AKSettings.useBluetooth = true
        
        self.nodes = nodes
        
        switch config {
        case "Sax":
            setupSaxConfig()
        default:
            setupDefaultConfig()
        }
        
        self.config = config
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        start()
        
    }
    
    func setupDefaultConfig(){
        for i in 0 ..< nodes {
            oscillators.append(AKOscillator())
            oscillators[i].frequency = 220 + i*220
            oscillators[i].amplitude = 0
            oscillators[i] >>> mixer
        }
    }
    
    func setupSaxConfig(){
        
    }
    
    func start(){
        switch config {
        case "Sax":
            for osc in oscillators {
                osc.start()
            }
        default:
            for osc in oscillators {
                osc.start()
            }
        }
    }
    
    func updateSound(distance: Float, rollVal: Double, index: Int){
        
        if !AudioKit.engine.isRunning {
            return
        }
        
        switch config {
        case "Sax":
            print("saxy")
        default:
            oscillators[index].amplitude = Double(1 - (abs(distance)/interactionDistance))
        }
        
    }
    
    
    
    
}

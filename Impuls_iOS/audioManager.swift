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
    
    private var nodes = 0
    private var config = "none"
    
    private var mixerSplitIdx = 4

    let samples = ["multiphonic1.wav", "multiphonic2.wav", "multiphonic3.wav", "multiphonic4.wav", "multiphonic5.wav", "multiphonic6.wav", "multiphonic7.wav", "multiphonic8.wav"]
    
    var oscillators = [AKOscillator]()
    var samplers = [AKWaveTable]()
    var mixer = AKMixer()
    var mixer1 = AKMixer()
    var mixer2 = AKMixer()
    
    var interactionDistance = 0.4
    
    
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
        mixer1 >>> mixer
        mixer2 >>> mixer
        
        for i in 0 ..< (nodes*2) {
            
            let file = try! AKAudioFile(readFileName: samples[i])
            let sampler = AKWaveTable(file: file)
            samplers.append(sampler)
            samplers[i].loopEnabled = true
            samplers[i].volume = 0
            
            
            if i < mixerSplitIdx {
                samplers[i] >>> mixer1
            } else {
                samplers[i] >>> mixer2
            }
        }
    }
    
    func start(){
        switch config {
        case "Sax":
            for sampler in samplers {
                sampler.start()
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
        
        let normalisedVal = Double(1 - (abs(distance)/interactionDistance))
        
        switch config {
        case "Sax":
            if samplers.count > 0 {
                samplers[index].volume = normalisedVal
                if conductor.config == "Sax" {
                    samplers[index + mixerSplitIdx].volume = normalisedVal
                }
            }
            
            let balance = min(1, max(0, (rollVal - 0)/90))
            mixer1.volume = 1 - balance
            mixer2.volume = balance
            
            
        default:
            oscillators[index].amplitude = normalisedVal
        }
        
    }
    
    
    
    
}

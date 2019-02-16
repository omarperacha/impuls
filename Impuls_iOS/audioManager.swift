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
    
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    
    
    func initialise(config: String, nodes: Int){
        lock.lock()
        defer {
            lock.unlock()
        }
        
        AKSettings.playbackWhileMuted = true
        AKSettings.useBluetooth = true
        
        for i in 0 ..< nodes {
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
    
    func updateSound(distance: Float, rollVal: Double, index: Int){
        
        oscillators[index].amplitude = Double(1 - (abs(distance)/interactionDistance))
    }
    
    
    
    
}

//
//  multipeer.swift
//  Impuls_iOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol AudioServiceDelegate {
    
    func connectedDevicesChanged(manager : AudioService, connectedDevices: [String])
    func distanceChanged(manager : AudioService, distance: String)
    
}

class AudioService : NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let audioServiceType = "impuls-ios"
    
    var delegate : AudioServiceDelegate?
    
    let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    private let serviceBrowser : MCNearbyServiceBrowser
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    override init() {
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: audioServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: audioServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()

        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    func send(distance : String) {
        NSLog("%@", "sendAudiot: \(distance) to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(distance.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
    
}

extension AudioService : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        if peerID.displayName != "omars-macbook.local" {
            return
        }
        invitationHandler(true, self.session)
    }
    
}

extension AudioService : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        if peerID.displayName != "omars-macbook.local" {
            return
        }
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension AudioService : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        if state.rawValue == 0 {
            self.serviceAdvertiser.startAdvertisingPeer()
        } else if state.rawValue == 2 {
            self.serviceAdvertiser.stopAdvertisingPeer()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.distanceChanged(manager: self, distance: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

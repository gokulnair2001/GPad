//
//  ConnectionManager.swift
//  GPad-iOS
//
//  Created by Gokul Nair on 19/03/26.
//


import Foundation
import MultipeerConnectivity
import Combine

/// Manages Multipeer Connectivity between iOS (browser) and Mac (advertiser).
/// iOS browses → discovers Mac → auto-invites → receives AppContextEvent.
/// On button tap iOS sends ButtonTapEvent back to Mac.
final class ConnectionManager: NSObject, ObservableObject {

    // MARK: - Published state

    @Published var isConnected = false
    @Published var connectedMacName: String?
    @Published var isSearching = false

    // App context received from Mac
    @Published var currentAppName: String?
    @Published var currentAppBundleId: String?
    @Published var currentAppIcon: UIImage?
    @Published var buttonLabels: [String] = []

    // MARK: - MC internals

    private static let serviceType = "gpad-macropad"   // 1-15 chars, lowercase + hyphen
    private let myPeerId: MCPeerID
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser

    // MARK: - Init

    override init() {
        myPeerId = MCPeerID(displayName: UIDevice.current.name)
        session  = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        browser  = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Self.serviceType)
        super.init()
        session.delegate = self
        browser.delegate = self
    }

    // MARK: - Public API

    func startSearching() {
        guard !isSearching else { return }
        isSearching = true
        browser.startBrowsingForPeers()
    }

    func stopSearching() {
        isSearching = false
        browser.stopBrowsingForPeers()
    }

    func disconnect() {
        session.disconnect()
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedMacName = nil
            self.currentAppName = nil
            self.currentAppBundleId = nil
            self.currentAppIcon = nil
            self.buttonLabels = []
        }
    }

    func sendButtonTap(_ buttonIndex: Int) {
        guard !session.connectedPeers.isEmpty else { return }

        let event = ButtonTapEvent(buttonIndex: buttonIndex)
        guard let eventData = try? JSONEncoder().encode(event) else { return }

        let envelope = MessageEnvelope(type: .buttonTap, payload: eventData)
        guard let data = try? JSONEncoder().encode(envelope) else { return }

        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

// MARK: - MCSessionDelegate

extension ConnectionManager: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedMacName = peerID.displayName
                self.stopSearching()
            case .notConnected:
                self.isConnected = false
                self.connectedMacName = nil
                self.currentAppName = nil
                self.currentAppBundleId = nil
                self.currentAppIcon = nil
                self.buttonLabels = []
                // Auto-resume search when disconnected
                self.startSearching()
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) else { return }

        switch envelope.type {
        case .appContext:
            guard let context = try? JSONDecoder().decode(AppContextEvent.self, from: envelope.payload) else { return }
            DispatchQueue.main.async {
                self.currentAppName = context.appName
                self.currentAppBundleId = context.bundleId
                self.currentAppIcon = context.iconData.flatMap { UIImage(data: $0) }
                self.buttonLabels = context.buttonLabels ?? []
            }
        default:
            break
        }
    }

    // Unused but required by protocol
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ConnectionManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Auto-invite any discovered Mac running GPad
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

import Foundation
import AppKit
@preconcurrency import MultipeerConnectivity

@Observable
final class MultipeerManager: NSObject {

    // MARK: - MultipeerConnectivity plumbing

    private let serviceType = "gpad-macropad"
    private nonisolated(unsafe) let myPeerID: MCPeerID
    private nonisolated(unsafe) var advertiser: MCNearbyServiceAdvertiser?
    private nonisolated(unsafe) var session: MCSession?

    // MARK: - Observable state

    var isConnected = false
    var connectedDeviceName: String?
    var actionLog: [String] = []

    // Context-aware state
    var currentAppName: String = "Desktop"
    var currentMapping: AppActionMapping = ActionRegistry.defaultMapping
    private var currentBundleID: String?
    private var urlPollTimer: Timer?
    private var lastDetectedURL: String?

    var buttonLabels: [String] {
        currentMapping.buttons.map(\.label)
    }

    // MARK: - Init

    override init() {
        self.myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac")
        super.init()
    }

    // MARK: - Lifecycle

    func start() {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        self.advertiser = advertiser
        advertiser.startAdvertisingPeer()

        startObservingFrontmostApp()
        log("Advertising as \"\(myPeerID.displayName)\"…")
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        session?.disconnect()
        stopURLPolling()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Foreground App Observation

    private func startObservingFrontmostApp() {
        // Set initial state
        updateFrontmostApp()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func frontmostAppChanged(_ notification: Notification) {
        updateFrontmostApp()
    }

    private let ownBundleID = Bundle.main.bundleIdentifier ?? ""

    private func updateFrontmostApp() {
        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = app?.bundleIdentifier

        // Ignore our own app — keep showing the previous context
        if bundleID == ownBundleID { return }

        currentBundleID = bundleID

        // If it's a browser, start polling the URL for site-specific mappings
        if BrowserHelper.isBrowser(bundleID) {
            startURLPolling()
            // Do an immediate check
            pollBrowserURL()
            return
        }

        stopURLPolling()
        lastDetectedURL = nil

        let appName = app?.localizedName ?? "Desktop"
        let mapping = ActionRegistry.mapping(for: bundleID)
        currentAppName = mapping.appName == "Default" ? appName : mapping.appName
        currentMapping = mapping

        sendAppContext()
        log("Context → \(currentAppName) [\(bundleID ?? "none")]")
    }

    // MARK: - Browser URL Polling

    private func startURLPolling() {
        guard urlPollTimer == nil else { return }
        urlPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollBrowserURL()
        }
    }

    private func stopURLPolling() {
        urlPollTimer?.invalidate()
        urlPollTimer = nil
    }

    private func pollBrowserURL() {
        guard let bundleID = currentBundleID,
              BrowserHelper.isBrowser(bundleID) else {
            stopURLPolling()
            return
        }

        let url = BrowserHelper.currentURL(for: bundleID)

        // Only update if URL changed
        guard url != lastDetectedURL else { return }
        lastDetectedURL = url

        if let siteRule = SiteActionRegistry.mapping(for: url) {
            currentAppName = siteRule.siteName
            currentMapping = siteRule.mapping
            sendAppContext()
            log("Site → \(siteRule.siteName) [\(url ?? "")]")
        } else {
            // Fall back to generic browser mapping
            let mapping = ActionRegistry.mapping(for: bundleID)
            let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Browser"
            currentAppName = mapping.appName == "Default" ? appName : mapping.appName
            currentMapping = mapping
            sendAppContext()
            log("Context → \(currentAppName) [\(url ?? "no URL")]")
        }
    }

    // MARK: - Send App Context to iOS

    private func sendAppContext() {
        guard let session = session,
              !session.connectedPeers.isEmpty else { return }

        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = currentBundleID ?? ""

        // Extract app icon as PNG data
        var iconData: Data? = nil
        if let icon = app?.icon {
            let cgRef = icon.cgImage(forProposedRect: nil, context: nil, hints: nil)
            if let cg = cgRef {
                let rep = NSBitmapImageRep(cgImage: cg)
                iconData = rep.representation(using: .png, properties: [:])
            }
        }

        let payload = AppContextPayload(
            appName: currentAppName,
            bundleId: bundleID,
            iconData: iconData,
            buttonLabels: buttonLabels
        )

        do {
            let payloadData = try JSONEncoder().encode(payload)
            let envelope = MessageEnvelope(type: "app_context", payload: payloadData)
            let data = try JSONEncoder().encode(envelope)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            log("Failed to send app_context: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let ts = formatter.string(from: Date())
        actionLog.insert("[\(ts)] \(message)", at: 0)
    }

    private func handleButtonTap(_ tap: ButtonTapPayload) {
        guard (1...3).contains(tap.buttonIndex) else {
            log("Invalid button index: \(tap.buttonIndex)")
            return
        }
        let buttonAction = currentMapping.buttons[tap.buttonIndex - 1]
        log("⚡ \(currentAppName) → \(buttonAction.label) (\(buttonAction.shortcut))")
        executeAction(buttonAction.action)
    }

    private func executeAction(_ action: ActionType) {
        switch action {
        case .keyboardShortcut(let keyCode, let modifiers):
            if !KeySimulator.hasAccessibilityPermission {
                KeySimulator.requestAccessibilityPermission()
                log("⚠ Accessibility permission required")
                return
            }
            KeySimulator.simulate(keyCode: keyCode, modifiers: modifiers)

        case .keySequence(let keys):
            if !KeySimulator.hasAccessibilityPermission {
                KeySimulator.requestAccessibilityPermission()
                log("⚠ Accessibility permission required")
                return
            }
            KeySimulator.simulateSequence(keys)

        case .mediaKey(let key):
            KeySimulator.simulateMediaKey(key)

        case .javaScript(let js):
            guard let bundleID = currentBundleID,
                  BrowserHelper.isBrowser(bundleID) else {
                log("⚠ JS actions only work in browsers")
                return
            }
            let _ = BrowserHelper.executeJavaScript(js, in: bundleID)

        case .none:
            log("Action not configured")
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedDeviceName = peerID.displayName
                self.log("Connected to \(peerID.displayName)")
            case .notConnected:
                self.isConnected = false
                self.connectedDeviceName = nil
                self.log("\(peerID.displayName) disconnected")
            case .connecting:
                self.log("Connecting to \(peerID.displayName)…")
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let envelope = try JSONDecoder().decode(MessageEnvelope.self, from: data)
                switch envelope.type {
                case "button_tap":
                    let tap = try JSONDecoder().decode(ButtonTapPayload.self, from: envelope.payload)
                    self.handleButtonTap(tap)
                default:
                    self.log("Unknown message: \(envelope.type)")
                }
            } catch {
                self.log("Decode error: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let session = self.session
        invitationHandler(true, session)
        Task { @MainActor in
            self.log("Accepted invitation from \(peerID.displayName)")
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.log("Advertising failed: \(error.localizedDescription)")
        }
    }
}

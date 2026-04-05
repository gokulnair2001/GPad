//
//  Models.swift
//  GPad-iOS
//
//  Created by Gokul Nair on 19/03/26.
//

import Foundation
import SwiftUI

// ╔══════════════════════════════════════════════════════════════╗
// ║  GPad Communication Contract                                ║
// ║  Shared schema between Mac (sender) and iOS (receiver)      ║
// ╚══════════════════════════════════════════════════════════════╝

// MARK: - iOS → Mac

/// Fired when the user taps a button
struct ButtonTapEvent: Codable {
    /// 1-based button index (1, 2, 3)
    let buttonIndex: Int
    let timestamp: TimeInterval

    init(buttonIndex: Int) {
        self.buttonIndex = buttonIndex
        self.timestamp = Date().timeIntervalSince1970
    }
}

// MARK: - Mac → iOS

/// Sent by the Mac whenever the frontmost app changes
struct AppContextEvent: Codable {
    /// Display name of the frontmost app (e.g. "Xcode", "Slack")
    let appName: String
    /// Bundle identifier (e.g. "com.apple.dt.Xcode")
    let bundleId: String
    /// PNG icon data (base64-encoded in JSON, raw bytes in Swift)
    let iconData: Data?
    /// Labels for buttons 1-3, top to bottom
    let buttonLabels: [String]?
}

// MARK: - Transport Envelope

enum MessageType: String, Codable {
    case buttonTap   = "button_tap"
    case heartbeat   = "heartbeat"
    case appContext  = "app_context"
}

struct MessageEnvelope: Codable {
    let type: MessageType
    let payload: Data
}

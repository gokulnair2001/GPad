import CoreGraphics
import AppKit
import IOKit.hidsystem

enum KeySimulator {

    /// Simulate a keyboard shortcut by posting CGEvents.
    /// Requires Accessibility permission.
    static func simulate(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    /// Simulate a system media key press (play/pause, next, previous).
    static func simulateMediaKey(_ key: MediaKeyType) {
        let keyCode: Int64
        switch key {
        case .playPause:     keyCode = Int64(NX_KEYTYPE_PLAY)
        case .nextTrack:     keyCode = Int64(NX_KEYTYPE_NEXT)
        case .previousTrack: keyCode = Int64(NX_KEYTYPE_PREVIOUS)
        }

        func postMediaKeyEvent(keyDown: Bool) {
            let flags: Int64 = keyDown ? 0xa00 : 0xb00
            let data1 = (keyCode << 16) | flags
            let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: Int(data1),
                data2: -1
            )
            event?.cgEvent?.post(tap: .cghidEventTap)
        }

        postMediaKeyEvent(keyDown: true)
        postMediaKeyEvent(keyDown: false)
    }

    /// Check if the app has Accessibility permission.
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the user for Accessibility permission.
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Key code constants

    static let kVK_A: CGKeyCode         = 0x00
    static let kVK_S: CGKeyCode         = 0x01
    static let kVK_D: CGKeyCode         = 0x02
    static let kVK_F: CGKeyCode         = 0x03
    static let kVK_G: CGKeyCode         = 0x05
    static let kVK_H: CGKeyCode         = 0x04
    static let kVK_B: CGKeyCode         = 0x0B
    static let kVK_Q: CGKeyCode         = 0x0C
    static let kVK_W: CGKeyCode         = 0x0D
    static let kVK_E: CGKeyCode         = 0x0E
    static let kVK_R: CGKeyCode         = 0x0F
    static let kVK_T: CGKeyCode         = 0x11
    static let kVK_Y: CGKeyCode         = 0x10
    static let kVK_U: CGKeyCode         = 0x20
    static let kVK_I: CGKeyCode         = 0x22
    static let kVK_O: CGKeyCode         = 0x1F
    static let kVK_P: CGKeyCode         = 0x23
    static let kVK_L: CGKeyCode         = 0x25
    static let kVK_J: CGKeyCode         = 0x26
    static let kVK_K: CGKeyCode         = 0x28
    static let kVK_N: CGKeyCode         = 0x2D
    static let kVK_M: CGKeyCode         = 0x2E
    static let kVK_C: CGKeyCode         = 0x08
    static let kVK_V: CGKeyCode         = 0x09
    static let kVK_X: CGKeyCode         = 0x07
    static let kVK_Z: CGKeyCode         = 0x06
    static let kVK_1: CGKeyCode         = 0x12
    static let kVK_2: CGKeyCode         = 0x13
    static let kVK_3: CGKeyCode         = 0x14
    static let kVK_4: CGKeyCode         = 0x15
    static let kVK_5: CGKeyCode         = 0x17
    static let kVK_6: CGKeyCode         = 0x16
    static let kVK_7: CGKeyCode         = 0x1A
    static let kVK_8: CGKeyCode         = 0x1C
    static let kVK_9: CGKeyCode         = 0x19
    static let kVK_0: CGKeyCode         = 0x1D
    static let kVK_Space: CGKeyCode     = 0x31
    static let kVK_Return: CGKeyCode    = 0x24
    static let kVK_Tab: CGKeyCode       = 0x30
    static let kVK_Escape: CGKeyCode    = 0x35
    static let kVK_Delete: CGKeyCode    = 0x33
    static let kVK_Grave: CGKeyCode     = 0x32  // ` / ~
    static let kVK_Comma: CGKeyCode     = 0x2B
    static let kVK_Period: CGKeyCode    = 0x2F
    static let kVK_Slash: CGKeyCode     = 0x2C
    static let kVK_Semicolon: CGKeyCode = 0x29
    static let kVK_Backslash: CGKeyCode = 0x2A
    static let kVK_LeftBracket: CGKeyCode  = 0x21
    static let kVK_RightBracket: CGKeyCode = 0x1E

    // Arrow keys
    static let kVK_UpArrow: CGKeyCode    = 0x7E
    static let kVK_DownArrow: CGKeyCode  = 0x7D
    static let kVK_LeftArrow: CGKeyCode  = 0x7B
    static let kVK_RightArrow: CGKeyCode = 0x7C

    /// Simulate a sequence of key presses with a short delay between them.
    static func simulateSequence(_ keys: [KeyPress]) {
        for (index, key) in keys.enumerated() {
            let delay = DispatchTimeInterval.milliseconds(index * 100)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                simulate(keyCode: key.keyCode, modifiers: key.modifiers)
            }
        }
    }
}

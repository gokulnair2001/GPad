import Foundation
import CoreGraphics

enum ActionType: Sendable {
    /// Simulate a keyboard shortcut via CGEvent.
    case keyboardShortcut(keyCode: CGKeyCode, modifiers: CGEventFlags)
    /// Simulate a sequence of key presses (e.g. GitHub's "g c" shortcut).
    case keySequence([KeyPress])
    /// Simulate a system media key (play/pause, next, previous).
    case mediaKey(MediaKeyType)
    /// Execute JavaScript in the current browser tab.
    case javaScript(String)
    /// No-op placeholder for actions not yet implemented.
    case none
}

struct KeyPress: Sendable {
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags
}

enum MediaKeyType: Sendable {
    case playPause
    case nextTrack
    case previousTrack
}

struct ButtonAction: Sendable {
    let label: String
    let shortcut: String       // human-readable display string
    let action: ActionType
}

struct AppActionMapping: Sendable {
    let appName: String
    let buttons: [ButtonAction] // exactly 3
}

// MARK: - Convenience initialiser for common modifier combos

private extension CGEventFlags {
    static let cmd: CGEventFlags = .maskCommand
    static let shift: CGEventFlags = .maskShift
    static let opt: CGEventFlags = .maskAlternate
    static let ctrl: CGEventFlags = .maskControl
}

private func kbd(_ key: CGKeyCode, _ mods: CGEventFlags) -> ActionType {
    .keyboardShortcut(keyCode: key, modifiers: mods)
}

enum ActionRegistry {

    // Alias key codes for readability
    private typealias K = KeySimulator

    /// Default mapping (Desktop / unknown apps).
    static let defaultMapping = AppActionMapping(
        appName: "Default",
        buttons: [
            ButtonAction(label: "Screenshot",     shortcut: "⌘⇧4",    action: kbd(K.kVK_4, [.cmd, .shift])),
            ButtonAction(label: "Lock Screen",    shortcut: "⌃⌘Q",     action: kbd(K.kVK_Q, [.ctrl, .cmd])),
            ButtonAction(label: "Do Not Disturb", shortcut: "—",       action: .none),
        ]
    )

    /// Bundle-ID → action mapping lookup table.
    static let mappings: [String: AppActionMapping] = [

        // Xcode
        "com.apple.dt.Xcode": AppActionMapping(
            appName: "Xcode",
            buttons: [
                ButtonAction(label: "Build", shortcut: "⌘B",   action: kbd(K.kVK_B, .cmd)),
                ButtonAction(label: "Run",   shortcut: "⌘R",   action: kbd(K.kVK_R, .cmd)),
                ButtonAction(label: "Test",  shortcut: "⌘U",   action: kbd(K.kVK_U, .cmd)),
            ]
        ),

        // Safari
        "com.apple.Safari": AppActionMapping(
            appName: "Safari",
            buttons: [
                ButtonAction(label: "New Tab",     shortcut: "⌘T",   action: kbd(K.kVK_T, .cmd)),
                ButtonAction(label: "Close Tab",   shortcut: "⌘W",   action: kbd(K.kVK_W, .cmd)),
                ButtonAction(label: "Reload",      shortcut: "⌘R",   action: kbd(K.kVK_R, .cmd)),
            ]
        ),

        // Slack
        "com.tinyspeck.slackmacgap": AppActionMapping(
            appName: "Slack",
            buttons: [
                ButtonAction(label: "Mute",    shortcut: "⌘⇧M", action: kbd(K.kVK_M, [.cmd, .shift])),
                ButtonAction(label: "Video",   shortcut: "⌘⇧V", action: kbd(K.kVK_V, [.cmd, .shift])),
                ButtonAction(label: "React 👍", shortcut: "—",   action: .none),
            ]
        ),

        // Finder
        "com.apple.finder": AppActionMapping(
            appName: "Finder",
            buttons: [
                ButtonAction(label: "New Window",   shortcut: "⌘N",    action: kbd(K.kVK_N, .cmd)),
                ButtonAction(label: "Go to Folder", shortcut: "⌘⇧G",   action: kbd(K.kVK_G, [.cmd, .shift])),
                ButtonAction(label: "Get Info",     shortcut: "⌘I",    action: kbd(K.kVK_I, .cmd)),
            ]
        ),

        // Terminal
        "com.apple.Terminal": AppActionMapping(
            appName: "Terminal",
            buttons: [
                ButtonAction(label: "New Tab",    shortcut: "⌘T", action: kbd(K.kVK_T, .cmd)),
                ButtonAction(label: "Clear",      shortcut: "⌘K", action: kbd(K.kVK_K, .cmd)),
                ButtonAction(label: "Split Pane", shortcut: "⌘D", action: kbd(K.kVK_D, .cmd)),
            ]
        ),

        // VS Code
        "com.microsoft.VSCode": AppActionMapping(
            appName: "VS Code",
            buttons: [
                ButtonAction(label: "Command Palette", shortcut: "⌘⇧P", action: kbd(K.kVK_P, [.cmd, .shift])),
                ButtonAction(label: "Toggle Terminal", shortcut: "⌃`",   action: kbd(K.kVK_Grave, .ctrl)),
                ButtonAction(label: "Go to File",      shortcut: "⌘P",  action: kbd(K.kVK_P, .cmd)),
            ]
        ),

        // Notes
        "com.apple.Notes": AppActionMapping(
            appName: "Notes",
            buttons: [
                ButtonAction(label: "New Note",  shortcut: "⌘N",   action: kbd(K.kVK_N, .cmd)),
                ButtonAction(label: "Bold",      shortcut: "⌘B",   action: kbd(K.kVK_B, .cmd)),
                ButtonAction(label: "Checklist", shortcut: "⌘⇧L",  action: kbd(K.kVK_L, [.cmd, .shift])),
            ]
        ),

        // Chrome
        "com.google.Chrome": AppActionMapping(
            appName: "Chrome",
            buttons: [
                ButtonAction(label: "New Tab",   shortcut: "⌘T",   action: kbd(K.kVK_T, .cmd)),
                ButtonAction(label: "Close Tab", shortcut: "⌘W",   action: kbd(K.kVK_W, .cmd)),
                ButtonAction(label: "Reload",    shortcut: "⌘R",   action: kbd(K.kVK_R, .cmd)),
            ]
        ),
    ]

    static func mapping(for bundleID: String?) -> AppActionMapping {
        guard let id = bundleID else { return defaultMapping }
        return mappings[id] ?? defaultMapping
    }
}

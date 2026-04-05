import Foundation
import CoreGraphics

private typealias K = KeySimulator

private func kbd(_ key: CGKeyCode, _ mods: CGEventFlags) -> ActionType {
    .keyboardShortcut(keyCode: key, modifiers: mods)
}

struct SiteRule {
    /// A substring or pattern to match against the URL (host or path).
    let urlContains: String
    /// Human-readable site name.
    let siteName: String
    /// 3-button mapping for this site.
    let mapping: AppActionMapping
}

enum SiteActionRegistry {

    static let rules: [SiteRule] = [

        // YouTube Music — media keys work globally, no JS permission needed
        SiteRule(
            urlContains: "music.youtube.com",
            siteName: "YT Music",
            mapping: AppActionMapping(
                appName: "YT Music",
                buttons: [
                    ButtonAction(label: "Play / Pause", shortcut: "▶︎⏸", action: .mediaKey(.playPause)),
                    ButtonAction(label: "Next Track",   shortcut: "⏭",   action: .mediaKey(.nextTrack)),
                    ButtonAction(label: "Prev Track",   shortcut: "⏮",   action: .mediaKey(.previousTrack)),
                ]
            )
        ),

        // YouTube — uses YouTube's built-in keyboard shortcuts (K, F, M, T)
        SiteRule(
            urlContains: "youtube.com",
            siteName: "YouTube",
            mapping: AppActionMapping(
                appName: "YouTube",
                buttons: [
                    ButtonAction(label: "Play / Pause",  shortcut: "K",  action: kbd(K.kVK_K, [])),
                    ButtonAction(label: "Fullscreen",    shortcut: "F",  action: kbd(K.kVK_F, [])),
                    ButtonAction(label: "Mute",          shortcut: "M",  action: kbd(K.kVK_M, [])),
                ]
            )
        ),

        // GitHub — uses GitHub's built-in keyboard shortcuts
        SiteRule(
            urlContains: "github.com",
            siteName: "GitHub",
            mapping: AppActionMapping(
                appName: "GitHub",
                buttons: [
                    ButtonAction(label: "Go to Code",     shortcut: "gc",   action: .keySequence([KeyPress(keyCode: K.kVK_G, modifiers: []), KeyPress(keyCode: K.kVK_C, modifiers: [])])),
                    ButtonAction(label: "Go to Issues",   shortcut: "gi",   action: .keySequence([KeyPress(keyCode: K.kVK_G, modifiers: []), KeyPress(keyCode: K.kVK_I, modifiers: [])])),
                    ButtonAction(label: "Go to PRs",      shortcut: "gp",   action: .keySequence([KeyPress(keyCode: K.kVK_G, modifiers: []), KeyPress(keyCode: K.kVK_P, modifiers: [])])),
                ]
            )
        ),

        // Spotify Web — media keys
        SiteRule(
            urlContains: "open.spotify.com",
            siteName: "Spotify",
            mapping: AppActionMapping(
                appName: "Spotify Web",
                buttons: [
                    ButtonAction(label: "Play / Pause", shortcut: "▶︎⏸", action: .mediaKey(.playPause)),
                    ButtonAction(label: "Next Track",   shortcut: "⏭",   action: .mediaKey(.nextTrack)),
                    ButtonAction(label: "Prev Track",   shortcut: "⏮",   action: .mediaKey(.previousTrack)),
                ]
            )
        ),

        // Google Meet — uses Meet's native keyboard shortcuts
        SiteRule(
            urlContains: "meet.google.com",
            siteName: "Google Meet",
            mapping: AppActionMapping(
                appName: "Google Meet",
                buttons: [
                    ButtonAction(label: "Mute",       shortcut: "⌘D",   action: kbd(K.kVK_D, .maskCommand)),
                    ButtonAction(label: "Camera",     shortcut: "⌘E",   action: kbd(K.kVK_E, .maskCommand)),
                    ButtonAction(label: "Hand",       shortcut: "⌃⌘H",  action: kbd(K.kVK_H, [.maskCommand, .maskControl])),
                ]
            )
        ),

        // Notion — uses Notion's native keyboard shortcuts
        SiteRule(
            urlContains: "notion.so",
            siteName: "Notion",
            mapping: AppActionMapping(
                appName: "Notion",
                buttons: [
                    ButtonAction(label: "New Page",    shortcut: "⌘N",   action: kbd(K.kVK_N, .maskCommand)),
                    ButtonAction(label: "Search",      shortcut: "⌘P",   action: kbd(K.kVK_P, .maskCommand)),
                    ButtonAction(label: "Toggle Side", shortcut: "⌘\\",  action: kbd(K.kVK_Backslash, .maskCommand)),
                ]
            )
        ),
    ]

    /// Find a site-specific mapping for a given URL. First match wins.
    static func mapping(for url: String?) -> SiteRule? {
        guard let url = url?.lowercased() else { return nil }
        return rules.first { url.contains($0.urlContains) }
    }
}

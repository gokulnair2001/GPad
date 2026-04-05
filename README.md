# GPad

Turn your iPhone into a context-aware 3-button macro pad for your Mac. GPad detects the frontmost app (and even the active website) and maps each button to the most useful action — no configuration needed.

![Platform](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## How It Works

1. **Launch both apps** — iPhone and Mac discover each other over the local network.
2. **Place your iPhone next to your Mac** — connection is automatic via Multipeer Connectivity.
3. **The Mac feeds context to the iPhone** — app name, icon, and button labels update in real-time as you switch apps.
4. **Tap a button** — the Mac executes the mapped action (keyboard shortcut, media key, AppleScript, etc.).

The iPhone acts as a beautiful dumb terminal with 3D keycap buttons. All intelligence lives on the Mac.

---

## Features

### iOS App
- **3D keycap-style buttons** with concave dish design, press animations, and layered depth effects
- **Live context bar** showing the Mac's frontmost app icon, name, and connection status
- **Haptic + audio feedback** on every button press
- **Auto-connect** — discovers and pairs with the Mac automatically; reconnects on disconnect
- **Always-on display** — idle timer disabled so the pad stays ready

### macOS App
- **Floating always-on-top panel** that never steals focus — shows current context, button actions, and an activity log
- **App-aware action mapping** out of the box for:
  - Xcode, VS Code, Safari, Chrome, Slack, Finder, Terminal, Notes
- **Website-aware action mapping** (polls the active browser tab URL):
  - YouTube / YouTube Music, GitHub, Spotify, Google Meet, Notion
- **Keyboard simulation** via `CGEvent` (shortcuts, key sequences, media keys)
- **Browser automation** via AppleScript (JavaScript execution, URL detection)
- **Fallback defaults** for unmapped apps: Screenshot, Lock Screen, Do Not Disturb

---

## Architecture

```
┌─────────────┐                          ┌──────────────────┐
│   iPhone     │  ── button_tap (JSON) ─▶ │      Mac         │
│              │                          │                  │
│  3 Buttons   │  ◀── app_context ──────  │  Action Engine   │
│  Info Bar    │      (icon, labels)      │  Floating Panel  │
└─────────────┘                          └──────────────────┘
        Multipeer Connectivity (Bonjour)
        Service: _gpad-macropad._tcp
        Encryption: Required
```

| Layer | Technology |
|---|---|
| Networking | `MultipeerConnectivity`, Bonjour |
| Serialization | Swift `Codable`, JSON, Base64 payloads |
| iOS UI | SwiftUI, `UIImpactFeedbackGenerator`, `AVAudioPlayer` |
| macOS UI | SwiftUI + AppKit (`NSPanel`, `NSWorkspace`) |
| Keyboard Input | `CoreGraphics` (`CGEvent`, `CGKeyCode`) |
| Media Keys | `IOKit` (`NX_KEYTYPE` constants) |
| Process Monitoring | `NSWorkspace.didActivateApplicationNotification` |
| Browser Automation | AppleScript (Safari, Chrome, Edge, Brave, Arc, Firefox) |

---

## Requirements

### iOS
- iOS 15+
- iPhone on the same local network as the Mac

### macOS
- macOS 12+
- **Accessibility permission** — required for keyboard simulation (prompted on first launch)
- **Automation (Apple Events) permission** — required for browser URL detection and JavaScript execution

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/GPad.git
```

### 2. Open the Xcode projects

- `GPad-iOS/GPad-iOS.xcodeproj` — build and run on your iPhone
- `GPad-MacOS/GPad-MacOS.xcodeproj` — build and run on your Mac

### 3. Grant permissions (macOS)

On first launch the Mac app will request:
- **Accessibility** — System Settings → Privacy & Security → Accessibility → enable GPad
- **Automation** — allow GPad to control browsers when prompted

### 4. Connect

Make sure both devices are on the same Wi-Fi network. The apps will discover each other automatically — no pairing code needed.

---

## Supported App Shortcuts

| App | Button 1 | Button 2 | Button 3 |
|---|---|---|---|
| **Xcode** | Build (⌘B) | Run (⌘R) | Show Inspector (⌘⌥0) |
| **VS Code** | Toggle Terminal (⌃`) | Command Palette (⇧⌘P) | Go to File (⌘P) |
| **Safari** | New Tab (⌘T) | Close Tab (⌘W) | Reload (⌘R) |
| **Chrome** | New Tab (⌘T) | Close Tab (⌘W) | Reload (⌘R) |
| **Slack** | New Message (⌘N) | Search (⌘K) | Toggle Sidebar (⇧⌘D) |
| **Finder** | New Finder Window (⌘N) | Toggle Hidden Files (⇧⌘.) | Get Info (⌘I) |
| **Terminal** | New Tab (⌘T) | Clear (⌘K) | Split Pane (⌘D) |
| **Notes** | New Note (⌘N) | Bold (⌘B) | Checklist (⇧⌘L) |
| *Default* | Screenshot (⇧⌘3) | Lock Screen (⌃⌘Q) | Do Not Disturb |

### Website-Specific Overrides (in any supported browser)

| Site | Button 1 | Button 2 | Button 3 |
|---|---|---|---|
| **YouTube** | Play/Pause (K) | Fullscreen (F) | Mute (M) |
| **YouTube Music** | Play/Pause | Next Track | Previous Track |
| **GitHub** | Go to Code (gc) | Go to Issues (gi) | Go to PRs (gp) |
| **Spotify** | Play/Pause | Next Track | Previous Track |
| **Google Meet** | Toggle Mic (⌘D) | Toggle Camera (⌘E) | Raise Hand (⌃⌘H) |
| **Notion** | New Page (⌘N) | Search (⌘P) | Toggle Sidebar (⌘\\) |

---

## Project Structure

```
GPad/
├── GPad-iOS/
│   └── GPad-iOS/
│       ├── GPad_iOSApp.swift        # App entry point
│       ├── ContentView.swift         # 3D keycap UI + info bar
│       ├── ConnectionManager.swift   # Multipeer client (browse + connect)
│       └── Models.swift              # Shared message types
│
├── GPad-MacOS/
│   └── GPad-MacOS/
│       ├── GPad_MacOSApp.swift       # App entry point + floating panel init
│       ├── ContentView.swift         # Main settings / status view
│       ├── FloatingPanelController.swift  # NSPanel (always-on-top)
│       ├── FloatingPanelView.swift   # Panel SwiftUI content
│       ├── MultipeerManager.swift    # Multipeer host (advertise + accept)
│       ├── ActionRegistry.swift      # Per-app button → action mappings
│       ├── SiteActionRegistry.swift  # Per-website button → action mappings
│       ├── KeySimulator.swift        # CGEvent keyboard + media key simulation
│       ├── BrowserHelper.swift       # URL polling + JS execution via AppleScript
│       └── Models.swift              # Shared message types
```

---

## License

MIT

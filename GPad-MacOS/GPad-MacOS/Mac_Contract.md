# GPad — Mac ↔ iOS Communication Contract

## Project Idea

GPad turns your iPhone into a physical-feeling macro pad that sits next to your Mac. The iOS app displays 3 blank, 3D keycap-style buttons stacked vertically, with an info bar at the top showing the current frontmost app's icon and name. When placed beside the Mac, it connects over the local network and acts as an external input device — like a Stream Deck, but simpler.

The Mac app knows which application is in the foreground and maps each of the 3 buttons to context-specific actions (keyboard shortcuts, AppleScript, shell commands, URL schemes). The Mac sends the frontmost app's icon and name to iOS so the info bar stays in sync. The Mac can also send button labels so each keycap shows what it does.

The iPhone sends only a button index (1–3) on tap. All intelligence — action mapping, context switching — lives on the Mac side.

---

## Transport

| Detail | Value |
|--------|-------|
| Framework | `MultipeerConnectivity` |
| Service type | `gpad-macropad` (Bonjour `_gpad-macropad._tcp`) |
| Role — Mac | **Advertiser** (`MCNearbyServiceAdvertiser`) |
| Role — iOS | **Browser** (`MCNearbyServiceBrowser`) |
| Encryption | `.required` |
| Serialisation | JSON via `Codable` |

All messages are wrapped in a **`MessageEnvelope`**:

```json
{
  "type": "button_tap | heartbeat | app_context",
  "payload": "<base64-encoded JSON of the inner type>"
}
```

> `payload` is the raw bytes of the inner JSON struct (`Data` is encoded by `JSONEncoder` as base64 automatically).

---

## iOS → Mac: `button_tap`

Sent when the user taps any of the 3 buttons.

```json
{
  "type": "button_tap",
  "payload": {
    "buttonIndex": 1,
    "timestamp": 1710835200.0
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `buttonIndex` | `Int` | 1-based button position (1, 2, or 3 — top to bottom) |
| `timestamp` | `Double` | Unix epoch seconds (`Date().timeIntervalSince1970`) |

---

## Mac → iOS: `app_context`

Sent whenever the frontmost application changes on the Mac.

```json
{
  "type": "app_context",
  "payload": {
    "appName": "Xcode",
    "bundleId": "com.apple.dt.Xcode",
    "iconData": "<base64-encoded PNG>",
    "buttonLabels": ["Build", "Run", "Test"]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `appName` | `String` | Display name of the frontmost app |
| `bundleId` | `String` | Bundle identifier of the frontmost app |
| `iconData` | `Data?` | PNG icon data (optional, base64-encoded) |
| `buttonLabels` | `[String]?` | Labels for buttons 1–3, top to bottom (optional) |

---

## Mac → iOS: `heartbeat` (optional)

Periodic keep-alive. Payload can be empty `{}` or omitted.

---

## Mac App Responsibilities

The Mac app owns all the logic:

1. **Advertise** `gpad-macropad` via `MCNearbyServiceAdvertiser`
2. **Accept** incoming invitations from iOS browsers
3. **Observe** frontmost app via `NSWorkspace.shared.frontmostApplication`
4. **Send** `app_context` to iOS whenever the frontmost app changes — include app name, bundle ID, icon PNG data, and the 3 button labels for the current app
5. **Map** app bundle ID → 3 actions (user-configurable per app)
6. **Receive** `button_tap` → execute the mapped action for that `buttonIndex` (AppleScript, keyboard shortcut, URL scheme, shell command)
7. **Accessibility**: Request permissions for keyboard simulation if needed

---

## Example Action Mappings (Mac-side only)

### Xcode
| Button | Label | Action |
|--------|-------|--------|
| 1 | Build | ⌘B |
| 2 | Run | ⌘R |
| 3 | Test | ⌘U |

### Slack
| Button | Label | Action |
|--------|-------|--------|
| 1 | Mute | ⌘⇧M |
| 2 | Video | ⌘⇧V |
| 3 | React 👍 | AppleScript |

### Finder (default)
| Button | Label | Action |
|--------|-------|--------|
| 1 | Screenshot | ⌘⇧4 |
| 2 | Lock Screen | Shell command |
| 3 | Do Not Disturb | Shortcut |

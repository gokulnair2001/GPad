import Foundation

enum BrowserHelper {

    /// Known browser bundle IDs.
    static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "org.mozilla.firefox",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",  // Arc
    ]

    static func isBrowser(_ bundleID: String?) -> Bool {
        guard let id = bundleID else { return false }
        return browserBundleIDs.contains(id)
    }

    /// Get the current tab URL from the frontmost browser.
    static func currentURL(for bundleID: String) -> String? {
        let script: String

        switch bundleID {
        case "com.apple.Safari":
            script = """
            tell application "Safari"
                if (count of windows) > 0 then
                    return URL of current tab of front window
                end if
            end tell
            """

        case "com.google.Chrome", "com.google.Chrome.canary",
             "com.brave.Browser", "com.microsoft.edgemac":
            let appName = appNameForBundleID(bundleID)
            script = """
            tell application "\(appName)"
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end tell
            """

        default:
            return nil
        }

        return runAppleScript(script)
    }

    /// Execute JavaScript in the current browser tab.
    static func executeJavaScript(_ js: String, in bundleID: String) -> String? {
        let escapedJS = js.replacingOccurrences(of: "\\", with: "\\\\")
                         .replacingOccurrences(of: "\"", with: "\\\"")
        let script: String

        switch bundleID {
        case "com.apple.Safari":
            script = """
            tell application "Safari"
                if (count of windows) > 0 then
                    return do JavaScript "\(escapedJS)" in current tab of front window
                end if
            end tell
            """

        case "com.google.Chrome", "com.google.Chrome.canary",
             "com.brave.Browser", "com.microsoft.edgemac":
            let appName = appNameForBundleID(bundleID)
            script = """
            tell application "\(appName)"
                if (count of windows) > 0 then
                    return execute front window's active tab javascript "\(escapedJS)"
                end if
            end tell
            """

        default:
            return nil
        }

        return runAppleScript(script)
    }

    // MARK: - Private

    private static func runAppleScript(_ source: String) -> String? {
        let appleScript = NSAppleScript(source: source)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript error: \(error)")
            return nil
        }
        return result?.stringValue
    }

    private static func appNameForBundleID(_ bundleID: String) -> String {
        switch bundleID {
        case "com.google.Chrome":         return "Google Chrome"
        case "com.google.Chrome.canary":  return "Google Chrome Canary"
        case "com.brave.Browser":         return "Brave Browser"
        case "com.microsoft.edgemac":     return "Microsoft Edge"
        default:                          return "Google Chrome"
        }
    }
}

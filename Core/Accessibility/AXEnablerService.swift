import ApplicationServices
import Cocoa

/// Service to check and request Accessibility permissions
final class AXEnablerService {
    static let shared = AXEnablerService()

    private init() {}

    /// Check if the app has Accessibility permission
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the user to enable Accessibility permission
    func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Enable enhanced UI mode for specific apps (e.g., Chrome, Firefox)
    func enableEnhancedUIMode(for bundleIdentifier: String) {
        // Apps that support AXEnhancedUserInterface
        let supportedApps: Set<String> = [
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "com.google.Chrome.beta",
            "com.google.Chrome.dev",
            "com.brave.Browser",
            "org.mozilla.firefox",
            "org.mozilla.nightly",
            "com.microsoft.edgemac",
            "com.spotify.client",
        ]

        guard supportedApps.contains(bundleIdentifier) else { return }

        // Find the running app
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        // Set AXEnhancedUserInterface to true
        let enhancedUI: CFBoolean = kCFBooleanTrue
        AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, enhancedUI)
    }
}

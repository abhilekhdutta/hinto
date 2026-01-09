import Cocoa

/// A tree structure containing all UI elements
final class UITree {
    var root: UIElement?
    var allElements: [UIElement] = []

    /// Flat list of clickable elements (deduplicated)
    var clickableElements: [UIElement] {
        let filtered = allElements.filter { element in
            isClickable(element)
        }

        // Deduplicate by frame position
        var seen = Set<String>()
        return filtered.filter { element in
            let key = "\(Int(element.frame.origin.x)),\(Int(element.frame.origin.y)),\(Int(element.frame.width)),\(Int(element.frame.height))"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    private func isClickable(_ element: UIElement) -> Bool {
        // Check screen bounds first (not included in static function for testability)
        guard isOnScreen(element.frame) else { return false }
        // Delegate to testable static function
        return Self.isClickable(role: element.role, frame: element.frame, isEnabled: element.isEnabled)
    }

    // MARK: - Testable Clickability Logic

    /// Determine if an element is clickable based on its properties.
    /// This is a pure function for testability.
    static func isClickable(role: String, frame: CGRect, isEnabled: Bool) -> Bool {
        let clickableRoles: Set<String> = [
            "AXButton",
            "AXLink",
            "AXMenuItem",
            "AXMenuBarItem",
            "AXCheckBox",
            "AXRadioButton",
            "AXPopUpButton",
            "AXMenuButton",
            "AXDisclosureTriangle",
            "AXIncrementor",
            "AXCell",
            "AXTab",
            "AXToolbarButton",
            "AXColorWell",
            "AXSlider",
            "AXTextField",
            "AXTextArea",
            "AXComboBox",
        ]

        // Skip isEnabled check for tab-like elements (iTerm2 tabs report enabled=false)
        let isTabLikeElement = role == "AXRadioButton" && frame.origin.y < 60

        // Must be enabled (skip for tab-like elements)
        if !isTabLikeElement {
            guard isEnabled else { return false }
        }

        // Must have a valid frame
        guard frame.width > 0 && frame.height > 0 else { return false }

        // Filter out elements at origin (0,0) - likely hidden/placeholder elements
        // Exception: menu bar items can have small x values
        if frame.origin.x == 0 && frame.origin.y == 0 {
            return false
        }

        // Filter out elements with unreasonable sizes (likely scroll views or containers)
        if frame.width > 2000 || frame.height > 2000 {
            return false
        }

        // Filter out elements with negative coordinates (off-screen)
        if frame.origin.y < -100 {
            return false
        }

        // Filter out very small elements (< 10px) - likely invisible or decorative
        if frame.width < 10 || frame.height < 10 {
            return false
        }

        // Filter out buttons very close to top edge (y < 20) but not menu bar items
        // These are often tab close buttons or other decorative buttons
        if role != "AXMenuBarItem" && frame.origin.y < 20 && frame.origin.y >= 0 {
            return false
        }

        // Allow AXStaticText as tab labels in IntelliJ/Java apps
        if role == "AXStaticText" {
            let y = frame.origin.y
            let width = frame.width
            // File tabs at top of window (y=55-90)
            let isFileTab = y >= 55 && y <= 90 && width >= 50
            // Tool window session tabs (Terminal, Run, Debug) - anywhere in window
            // Identified by: moderate width (30-200), reasonable height, not at very top
            let isSessionTab = y > 100 && width >= 30 && width <= 200
            return isFileTab || isSessionTab
        }

        return clickableRoles.contains(role)
    }

    private func isOnScreen(_ frame: CGRect) -> Bool {
        // Check against all screens
        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            if frame.intersects(screenFrame) {
                return true
            }
        }

        // Also accept elements in the menu bar area (y > screen height - 30)
        if let mainScreen = NSScreen.main {
            let menuBarY = mainScreen.frame.height - 30
            if frame.origin.y >= menuBarY || frame.origin.y <= 30 {
                return true
            }
        }

        return false
    }
}

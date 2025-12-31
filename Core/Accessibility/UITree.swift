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

        // Must be enabled
        guard element.isEnabled else { return false }

        // Must have a valid frame
        guard element.frame.width > 0 && element.frame.height > 0 else { return false }

        // Filter out elements at origin (0,0) - likely hidden/placeholder elements
        // Exception: menu bar items can have small x values
        if element.frame.origin.x == 0 && element.frame.origin.y == 0 {
            return false
        }

        // Filter out elements with unreasonable sizes (likely scroll views or containers)
        if element.frame.width > 2000 || element.frame.height > 2000 {
            return false
        }

        // Filter out elements with negative coordinates (off-screen)
        if element.frame.origin.y < -100 {
            return false
        }

        // Filter out very small elements (< 10px) - likely invisible or decorative
        if element.frame.width < 10 || element.frame.height < 10 {
            return false
        }

        // Filter out buttons very close to top edge (y < 20) but not menu bar items
        // These are often tab close buttons or other decorative buttons
        if element.role != "AXMenuBarItem" && element.frame.origin.y < 20 && element.frame.origin.y >= 0 {
            return false
        }

        // Must be on screen
        guard isOnScreen(element.frame) else { return false }

        // Allow AXStaticText in tab bar area (y=55-90) as tab labels in IntelliJ/Java apps
        if element.role == "AXStaticText" {
            let y = element.frame.origin.y
            return y >= 55 && y <= 90 && element.frame.width >= 50
        }

        return clickableRoles.contains(element.role)
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

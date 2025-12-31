import ApplicationServices
import Cocoa

/// Utility class for performing click actions
final class ClickUtils {
    static let shared = ClickUtils()

    private init() {}

    // MARK: - Click Actions

    /// Perform a left click on a UI element
    func leftClick(on element: UIElement) -> Bool {
        log("ClickUtils: leftClick on role=\(element.role) frame=\(element.frame)")

        // For text fields and text areas, use focus + click
        if isTextInput(element.role) {
            // Try to focus first
            _ = performAccessibilityFocus(on: element.axElement)
            // Then simulate click to place cursor
            return simulateClick(at: element.frame.center, button: .left)
        }

        // For certain elements, AXPress doesn't work properly - use simulated click
        // - AXRadioButton in Java apps
        // - AXStaticText tab labels
        // - AXLink in web browsers (AXPress may navigate instead of focus)
        // - AXWebArea content elements
        let forceSimulatedClick = ["AXRadioButton", "AXTab", "AXStaticText", "AXLink", "AXWebArea"]
            .contains(element.role)

        if !forceSimulatedClick {
            // For buttons and other controls, try accessibility action first
            let pressResult = performAccessibilityPress(on: element.axElement)
            log("ClickUtils: AXPress result = \(pressResult)")

            if pressResult {
                return true
            }
        }

        // Fallback to simulated click
        log("ClickUtils: Using simulateClick at \(element.frame.center)")
        return simulateClick(at: element.frame.center, button: .left)
    }

    private func isTextInput(_ role: String) -> Bool {
        let textRoles = ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"]
        return textRoles.contains(role)
    }

    /// Perform a right click on a UI element
    func rightClick(on element: UIElement) -> Bool {
        let point = element.frame.center
        log("ClickUtils: rightClick at \(point)")

        // Move cursor first
        moveCursor(to: point)

        // Try Control+Click approach (traditional macOS right-click)
        // This works better with some apps, especially Java apps
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            log("ClickUtils: Failed to create event source")
            return false
        }

        guard let downEvent = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            log("ClickUtils: Failed to create mouseDown event")
            return false
        }

        guard let upEvent = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            log("ClickUtils: Failed to create mouseUp event")
            return false
        }

        // Add Control modifier (Control+Click = right-click on macOS)
        downEvent.flags = .maskControl
        upEvent.flags = .maskControl

        downEvent.post(tap: .cgSessionEventTap)
        usleep(50000) // 50ms
        upEvent.post(tap: .cgSessionEventTap)

        log("ClickUtils: Control+Click events posted")
        return true
    }

    /// Perform a double click on a UI element
    func doubleClick(on element: UIElement) -> Bool {
        let point = element.frame.center
        return simulateClick(at: point, button: .left, clickCount: 2)
    }

    /// Perform a command-click (open in new tab)
    func commandClick(on element: UIElement) -> Bool {
        let point = element.frame.center
        return simulateClick(at: point, button: .left, modifiers: .maskCommand)
    }

    // MARK: - Accessibility Actions

    private func performAccessibilityPress(on element: AXUIElement) -> Bool {
        let error = AXUIElementPerformAction(element, kAXPressAction as CFString)
        return error == .success
    }

    private func performAccessibilityFocus(on element: AXUIElement) -> Bool {
        // Try setting focused attribute
        let focused: CFBoolean = kCFBooleanTrue
        let error = AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, focused)
        return error == .success
    }

    /// Perform accessibility show menu action (right-click equivalent)
    func performShowMenu(on element: AXUIElement) -> Bool {
        let error = AXUIElementPerformAction(element, kAXShowMenuAction as CFString)
        return error == .success
    }

    // MARK: - Mouse Simulation

    /// Simulate a mouse click at a specific point
    func simulateClick(
        at point: CGPoint,
        button: CGMouseButton = .left,
        clickCount: Int = 1,
        modifiers: CGEventFlags = []
    ) -> Bool {
        let mouseDown: CGEventType
        let mouseUp: CGEventType

        switch button {
        case .left:
            mouseDown = .leftMouseDown
            mouseUp = .leftMouseUp
        case .right:
            mouseDown = .rightMouseDown
            mouseUp = .rightMouseUp
        case .center:
            mouseDown = .otherMouseDown
            mouseUp = .otherMouseUp
        @unknown default:
            return false
        }

        // Move cursor to position first
        moveCursor(to: point)

        // Create and post click events
        for i in 0 ..< clickCount {
            guard let downEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: mouseDown,
                mouseCursorPosition: point,
                mouseButton: button
            ) else { return false }

            guard let upEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: mouseUp,
                mouseCursorPosition: point,
                mouseButton: button
            ) else { return false }

            // Set click count for double/triple click
            downEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i + 1))
            upEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i + 1))

            // Apply modifiers
            if !modifiers.isEmpty {
                downEvent.flags = modifiers
                upEvent.flags = modifiers
            }

            downEvent.post(tap: .cghidEventTap)

            // Small delay for right-click to register (context menu needs time)
            if button == .right {
                usleep(50000) // 50ms
            }

            upEvent.post(tap: .cghidEventTap)

            // Small delay between clicks for double-click
            if clickCount > 1 && i < clickCount - 1 {
                usleep(50000) // 50ms
            }
        }

        return true
    }

    /// Move cursor to a specific point
    func moveCursor(to point: CGPoint) {
        // Use CGWarpMouseCursorPosition for more reliable cursor positioning
        CGWarpMouseCursorPosition(point)

        // Also post a move event to ensure apps recognize the cursor position
        guard let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }

        moveEvent.post(tap: .cghidEventTap)
    }

    /// Get current cursor position
    var cursorPosition: CGPoint {
        NSEvent.mouseLocation
    }
}

// MARK: - CGRect Extension

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

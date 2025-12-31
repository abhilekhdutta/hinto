import ApplicationServices
import Cocoa

/// Represents a UI element obtained from the Accessibility API
final class UIElement: Identifiable, Hashable {
    let id: UUID = .init()
    let axElement: AXUIElement
    let role: String
    let frame: CGRect
    let title: String?
    let identifier: String?
    let isEnabled: Bool

    var label: String = ""
    var children: [UIElement] = []
    weak var parent: UIElement?

    init(axElement: AXUIElement) {
        self.axElement = axElement
        role = axElement.role ?? "Unknown"
        frame = axElement.frame ?? .zero
        title = axElement.title
        identifier = axElement.identifier
        isEnabled = axElement.isEnabled
    }

    /// Initialize with a custom frame (for menu bar extras with missing size info)
    init(axElement: AXUIElement, customFrame: CGRect) {
        self.axElement = axElement
        role = axElement.role ?? "Unknown"
        frame = customFrame
        title = axElement.title
        identifier = axElement.identifier
        isEnabled = axElement.isEnabled
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: UIElement, rhs: UIElement) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Actions

    func performClick() -> Bool {
        var error = AXUIElementPerformAction(axElement, kAXPressAction as CFString)
        if error == .success {
            return true
        }

        // Fallback: try AXOpen for links
        error = AXUIElementPerformAction(axElement, "AXOpen" as CFString)
        if error == .success {
            return true
        }

        // Fallback: simulate mouse click at element center
        return simulateMouseClick()
    }

    func performRightClick() -> Bool {
        return simulateMouseClick(button: .right)
    }

    private func simulateMouseClick(button: CGMouseButton = .left) -> Bool {
        let centerPoint = CGPoint(x: frame.midX, y: frame.midY)

        let mouseDown: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let mouseUp: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp

        guard let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseDown,
            mouseCursorPosition: centerPoint,
            mouseButton: button
        ) else { return false }

        guard let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseUp,
            mouseCursorPosition: centerPoint,
            mouseButton: button
        ) else { return false }

        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)

        return true
    }
}

// MARK: - AXUIElement Extensions

extension AXUIElement {
    var role: String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXRoleAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? String
    }

    var title: String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXTitleAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? String
    }

    var identifier: String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXIdentifierAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? String
    }

    var frame: CGRect? {
        guard let position = position, let size = size else { return nil }
        return CGRect(origin: position, size: size)
    }

    var position: CGPoint? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXPositionAttribute as CFString, &value)
        guard error == .success, let axValue = value else { return nil }

        var point = CGPoint.zero
        AXValueGetValue(axValue as! AXValue, .cgPoint, &point)
        return point
    }

    var size: CGSize? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXSizeAttribute as CFString, &value)
        guard error == .success, let axValue = value else { return nil }

        var size = CGSize.zero
        AXValueGetValue(axValue as! AXValue, .cgSize, &size)
        return size
    }

    var isEnabled: Bool {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXEnabledAttribute as CFString, &value)
        guard error == .success else { return true }
        return (value as? Bool) ?? true
    }

    var children: [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXChildrenAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }

    var visibleChildren: [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXVisibleChildrenAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }

    var childrenInNavigationOrder: [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, "AXChildrenInNavigationOrder" as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }

    var parent: AXUIElement? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXParentAttribute as CFString, &value)
        guard error == .success else { return nil }
        return (value as! AXUIElement)
    }

    var tabs: [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, kAXTabsAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }
}

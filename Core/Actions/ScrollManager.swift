import Cocoa

/// Manages scrolling actions
final class ScrollManager {
    static let shared = ScrollManager()

    /// Scroll speed in pixels per event
    var scrollSpeed: CGFloat = 50

    /// Dash scroll multiplier (when holding Shift)
    var dashMultiplier: CGFloat = 3.0

    private init() {}

    // MARK: - Scroll Actions

    /// Scroll up
    func scrollUp(fast: Bool = false) {
        let delta = fast ? scrollSpeed * dashMultiplier : scrollSpeed
        scroll(deltaY: delta)
    }

    /// Scroll down
    func scrollDown(fast: Bool = false) {
        let delta = fast ? scrollSpeed * dashMultiplier : scrollSpeed
        scroll(deltaY: -delta)
    }

    /// Scroll left
    func scrollLeft(fast: Bool = false) {
        let delta = fast ? scrollSpeed * dashMultiplier : scrollSpeed
        scroll(deltaX: delta)
    }

    /// Scroll right
    func scrollRight(fast: Bool = false) {
        let delta = fast ? scrollSpeed * dashMultiplier : scrollSpeed
        scroll(deltaX: -delta)
    }

    /// Scroll to top of content
    func scrollToTop() {
        // Scroll with large delta
        for _ in 0 ..< 50 {
            scroll(deltaY: 1000)
        }
    }

    /// Scroll to bottom of content
    func scrollToBottom() {
        for _ in 0 ..< 50 {
            scroll(deltaY: -1000)
        }
    }

    /// Scroll half page up
    func scrollHalfPageUp() {
        guard let screenHeight = NSScreen.main?.frame.height else { return }
        scroll(deltaY: screenHeight / 2)
    }

    /// Scroll half page down
    func scrollHalfPageDown() {
        guard let screenHeight = NSScreen.main?.frame.height else { return }
        scroll(deltaY: -screenHeight / 2)
    }

    // MARK: - Private

    private func scroll(deltaX: CGFloat = 0, deltaY: CGFloat = 0) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(deltaY),
            wheel2: Int32(deltaX),
            wheel3: 0
        ) else { return }

        event.post(tap: .cghidEventTap)
    }
}

// MARK: - Scroll Key Bindings

extension ScrollManager {
    /// Handle vim-style scroll key
    func handleScrollKey(_ key: String, shift: Bool) -> Bool {
        switch key.lowercased() {
        case "j":
            scrollDown(fast: shift)
            return true
        case "k":
            scrollUp(fast: shift)
            return true
        case "h":
            scrollLeft(fast: shift)
            return true
        case "l":
            scrollRight(fast: shift)
            return true
        case "d":
            scrollHalfPageDown()
            return true
        case "u":
            scrollHalfPageUp()
            return true
        case "g":
            // gg = scroll to top (needs state tracking)
            scrollToTop()
            return true
        default:
            return false
        }
    }
}

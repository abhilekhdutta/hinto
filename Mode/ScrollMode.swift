import Cocoa

/// Controller for scroll mode
final class ScrollModeController {
    private let scrollManager = ScrollManager.shared
    private var isActive = false
    private var eventMonitor: Any?

    // MARK: - Activation

    func activate() {
        guard !isActive else { return }
        isActive = true

        print("ScrollMode: Activated")

        // Monitor key events for scroll commands
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event)
        }
    }

    func deactivate() {
        guard isActive else { return }
        isActive = false

        print("ScrollMode: Deactivated")

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    // MARK: - Key Handling

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let characters = event.charactersIgnoringModifiers else {
            return event
        }

        let shift = event.modifierFlags.contains(.shift)

        // Handle escape to exit scroll mode
        if event.keyCode == 53 { // Escape
            deactivate()
            return nil
        }

        // Handle scroll keys
        switch characters.lowercased() {
        case "j":
            scrollManager.scrollDown(fast: shift)
            return nil

        case "k":
            scrollManager.scrollUp(fast: shift)
            return nil

        case "h":
            scrollManager.scrollLeft(fast: shift)
            return nil

        case "l":
            scrollManager.scrollRight(fast: shift)
            return nil

        case "d":
            scrollManager.scrollHalfPageDown()
            return nil

        case "u":
            scrollManager.scrollHalfPageUp()
            return nil

        case "g":
            // Could implement gg for scroll to top
            // Would need state tracking for double-tap
            scrollManager.scrollToTop()
            return nil

        default:
            return event
        }
    }
}

import Cocoa

/// The current interaction mode
enum InteractionMode {
    case click
    case scroll
}

/// Main controller that manages the click mode lifecycle
final class ModeController {
    // MARK: - Properties

    private let uiTreeBuilder = UITreeBuilder()
    private let labelMaker = LabelMaker()
    private let inputSourceManager = InputSourceManager.shared
    private let scrollManager = ScrollManager.shared

    private var overlayController: OverlayWindowController?
    private var searchBarController: SearchBarWindowController?

    private var currentElements: [UIElement] = []
    private var filteredElements: [UIElement] = []
    private var highlightedElement: UIElement? // Track currently highlighted element for scroll targeting

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    private(set) var isActive = false
    private(set) var currentMode: InteractionMode = .click

    // MARK: - Initialization

    init() {
        setupUI()
        setupNotifications()
    }

    private func setupNotifications() {
        // Deactivate when active app changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppSwitch),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func handleAppSwitch(_ notification: Notification) {
        guard isActive else { return }

        // Check if the activated app is not our app
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier
        {
            log("ModeController: App switched, cancelling")
            deactivate()
        }
    }

    private func setupUI() {
        overlayController = OverlayWindowController()
        searchBarController = SearchBarWindowController()

        // Setup search bar callbacks
        searchBarController?.onSearchTextChanged = { [weak self] text in
            self?.handleSearchTextChanged(text)
        }

        searchBarController?.onReturn = { [weak self] shift in
            self?.handleReturn(shift: shift)
        }

        searchBarController?.onEscape = { [weak self] in
            self?.deactivate()
        }

        searchBarController?.onTab = { [weak self] in
            self?.toggleMode()
        }

        searchBarController?.onScrollKey = { [weak self] key, shift in
            self?.handleScrollKey(key, shift: shift)
        }
    }

    // MARK: - Public Methods

    /// Toggle activation state
    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    /// Activate click mode
    func activate() {
        guard !isActive else { return }
        isActive = true
        currentMode = .click

        log("ModeController: Activating")

        // Start monitoring mouse clicks to cancel on click
        startMouseClickMonitor()

        // Show search bar first for immediate feedback
        log("ModeController: Showing search bar")
        searchBarController?.show()

        // Build UI tree in background to avoid blocking
        log("ModeController: Starting UI scan...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let tree = self.uiTreeBuilder.buildTreeForAllScreens()
            let elements = tree.clickableElements

            DispatchQueue.main.async {
                // Check if still active
                guard self.isActive else {
                    log("ModeController: Scan completed but deactivated, discarding results")
                    return
                }

                log("ModeController: Found \(elements.count) clickable elements")

                // Log all elements for debugging
                log("=== All clickable elements ===")
                for (index, element) in elements.enumerated() {
                    let frame = element.frame
                    let title = element.title ?? "nil"
                    log(
                        "[\(index)] role=\(element.role) frame=(\(Int(frame.origin.x)),\(Int(frame.origin.y)),\(Int(frame.width)),\(Int(frame.height))) title=\"\(title)\""
                    )
                }
                log("=== End of elements ===")

                self.currentElements = elements
                self.labelMaker.assignLabels(to: &self.currentElements)
                self.filteredElements = self.currentElements

                // Only show labels if still in click mode (race condition guard)
                guard self.currentMode == .click else {
                    log("ModeController: Scan completed but in scroll mode, labels ready for later")
                    return
                }

                // Show overlay with labels
                log("ModeController: Showing overlay")
                self.overlayController?.showLabels(for: self.currentElements)
            }
        }
    }

    /// Deactivate click mode
    func deactivate() {
        guard isActive else { return }
        isActive = false

        log("ModeController: Deactivating")

        // Stop mouse click monitor
        stopMouseClickMonitor()

        // Hide UI
        overlayController?.hide()
        searchBarController?.hide()

        // Restore input source
        inputSourceManager.restoreSavedInputSource()

        // Clear state
        currentElements.removeAll()
        filteredElements.removeAll()
        highlightedElement = nil
    }

    // MARK: - Mouse Click Monitoring

    private func startMouseClickMonitor() {
        stopMouseClickMonitor()

        // Global monitor for clicks on other apps
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
        ]) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            log("ModeController: Global mouse click detected, cancelling")
            DispatchQueue.main.async {
                self.deactivate()
            }
        }

        // Local monitor for clicks on our own windows (search bar)
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
        ]) { [weak self] event in
            guard let self = self, self.isActive else { return event }

            // Check if click is on the search bar text field - allow it
            if let window = event.window,
               window == self.searchBarController?.window
            {
                // Allow clicks on search bar
                return event
            }

            // Cancel on any other click
            log("ModeController: Local mouse click detected, cancelling")
            DispatchQueue.main.async {
                self.deactivate()
            }
            return nil // Consume the event
        }
    }

    private func stopMouseClickMonitor() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
    }

    // MARK: - Private Methods

    private func handleSearchTextChanged(_ text: String) {
        if text.isEmpty {
            filteredElements = currentElements
            highlightedElement = nil
            overlayController?.filterLabels(prefix: "")
            return
        }

        // Filter elements by label prefix
        filteredElements = labelMaker.filterByPrefix(text, elements: currentElements)
        overlayController?.filterLabels(prefix: text)

        // Check for exact match
        if let match = labelMaker.findExactMatch(text, in: currentElements) {
            // Highlight the matched element
            highlightedElement = match
            overlayController?.highlightElement(match)

            // Auto-click if enabled (check Shift for right-click)
            if Preferences.shared.autoClickEnabled {
                let shift = NSEvent.modifierFlags.contains(.shift)
                log("ModeController: Auto-click, shift=\(shift)")
                performClick(on: match, rightClick: shift)
            }
        } else if filteredElements.count == 1 && filteredElements[0].label == text.uppercased() {
            // Single match that equals the search text
            highlightedElement = filteredElements[0]
            overlayController?.highlightElement(filteredElements[0])

            if Preferences.shared.autoClickEnabled {
                let shift = NSEvent.modifierFlags.contains(.shift)
                performClick(on: filteredElements[0], rightClick: shift)
            }
        } else if filteredElements.count == 1 {
            // Single filtered element - highlight it
            highlightedElement = filteredElements[0]
            overlayController?.highlightElement(filteredElements[0])
        } else {
            highlightedElement = nil
        }
    }

    private func handleReturn(shift: Bool) {
        // Only handle return in click mode
        guard currentMode == .click else { return }

        // If there's exactly one filtered element, click it
        if let element = filteredElements.first, filteredElements.count == 1 {
            performClick(on: element, rightClick: shift)
            return
        }

        // Otherwise, try to find exact match with current search text
        let searchText = searchBarController?.searchText ?? ""
        if let match = labelMaker.findExactMatch(searchText, in: currentElements) {
            performClick(on: match, rightClick: shift)
        }
    }

    private func toggleMode() {
        switch currentMode {
        case .click:
            currentMode = .scroll
            log("ModeController: Switched to scroll mode")
            overlayController?.hide()
            searchBarController?.setMode(.scroll)

            // Move cursor to highlighted element for targeted scrolling
            if let element = highlightedElement {
                log("ModeController: Moving cursor to \(element.frame.center) for scroll")
                ClickUtils.shared.moveCursor(to: element.frame.center)
            }
        case .scroll:
            currentMode = .click
            log("ModeController: Switched to click mode")
            overlayController?.showLabels(for: currentElements)
            searchBarController?.setMode(.click)
        }
    }

    private func handleScrollKey(_ key: String, shift: Bool) {
        guard currentMode == .scroll else { return }

        switch key.lowercased() {
        case "j":
            scrollManager.scrollDown(fast: shift)
        case "k":
            scrollManager.scrollUp(fast: shift)
        case "h":
            scrollManager.scrollLeft(fast: shift)
        case "l":
            scrollManager.scrollRight(fast: shift)
        case "d":
            scrollManager.scrollHalfPageDown()
        case "u":
            scrollManager.scrollHalfPageUp()
        case "g":
            scrollManager.scrollToTop()
        default:
            break
        }
    }

    private func performClick(on element: UIElement, rightClick: Bool) {
        log("ModeController: performClick rightClick=\(rightClick)")
        deactivate()

        // Longer delay before clicking to allow UI to hide completely
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Move mouse to target first
            ClickUtils.shared.moveCursor(to: element.frame.center)

            // Activate the frontmost app to ensure it receives the click
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                frontApp.activate()
            }

            // Longer delay for right-click (context menus need more time)
            let delay = rightClick ? 0.1 : 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if rightClick {
                    log("ModeController: Executing right-click at \(element.frame.center)")
                    _ = ClickUtils.shared.rightClick(on: element)
                } else {
                    _ = ClickUtils.shared.leftClick(on: element)
                }
            }
        }
    }
}

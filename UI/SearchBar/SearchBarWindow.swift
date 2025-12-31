import Cocoa

/// Window controller for the search bar
final class SearchBarWindowController: NSWindowController {
    private let searchBarView: SearchBarView

    /// Callback when search text changes
    var onSearchTextChanged: ((String) -> Void)?

    /// Callback when user presses Return
    var onReturn: ((Bool) -> Void)? // Bool indicates if Shift was held

    /// Callback when user presses Escape
    var onEscape: (() -> Void)?

    /// Callback when user presses Tab (to switch modes)
    var onTab: (() -> Void)?

    /// Callback when user presses a scroll key (J/K/H/L/D/U/G)
    var onScrollKey: ((String, Bool) -> Void)? // (key, shift)

    init() {
        searchBarView = SearchBarView()

        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 280, height: 70))
        panel.contentView = searchBarView

        super.init(window: panel)

        setupCallbacks()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCallbacks() {
        searchBarView.onTextChanged = { [weak self] text in
            self?.onSearchTextChanged?(text)
        }

        searchBarView.onReturn = { [weak self] shift in
            self?.onReturn?(shift)
        }

        searchBarView.onEscape = { [weak self] in
            self?.onEscape?()
        }

        searchBarView.onTab = { [weak self] in
            self?.onTab?()
        }

        searchBarView.onScrollKey = { [weak self] key, shift in
            self?.onScrollKey?(key, shift)
        }
    }

    // MARK: - Public Methods

    /// Show the search bar centered on the main screen
    func show() {
        guard let screen = NSScreen.main else { return }

        let windowWidth: CGFloat = 280
        let windowHeight: CGFloat = 70

        let x = (screen.frame.width - windowWidth) / 2
        let y = screen.frame.height - 200 // Near top of screen

        window?.setFrame(
            NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            display: true
        )
        window?.makeKeyAndOrderFront(nil)
        searchBarView.focus()
    }

    /// Hide the search bar
    func hide() {
        window?.orderOut(nil)
        searchBarView.clear()
        searchBarView.setMode(.click) // Reset mode and stop monitors
    }

    /// Get current search text
    var searchText: String {
        searchBarView.text
    }

    /// Clear the search text
    func clear() {
        searchBarView.clear()
    }

    /// Set the current mode (click or scroll)
    func setMode(_ mode: InteractionMode) {
        searchBarView.setMode(mode)
    }
}

// MARK: - Search Bar View

final class SearchBarView: NSView {
    private let textField: NSTextField
    private let hintLabel: NSTextField
    private let backgroundView: NSVisualEffectView

    // Scroll mode UI
    private let scrollContainer: NSStackView
    private var keyCapViews: [String: KeyCapView] = [:]

    private var currentMode: InteractionMode = .click
    private var scrollTimer: Timer?
    private var currentScrollKey: String?
    private var currentScrollShift: Bool = false
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    var onTextChanged: ((String) -> Void)?
    var onReturn: ((Bool) -> Void)?
    var onEscape: (() -> Void)?
    var onTab: (() -> Void)?
    var onScrollKey: ((String, Bool) -> Void)?

    var text: String {
        textField.stringValue
    }

    override init(frame frameRect: NSRect) {
        backgroundView = NSVisualEffectView()
        textField = NSTextField()
        hintLabel = NSTextField(labelWithString: "")
        scrollContainer = NSStackView()

        super.init(frame: frameRect)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Transparent background with slight blur
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 12
        backgroundView.layer?.masksToBounds = true
        backgroundView.alphaValue = 0.85 // Make the whole view more transparent
        addSubview(backgroundView)

        // Text field (click mode)
        textField.isBordered = false
        textField.drawsBackground = false
        textField.font = .monospacedSystemFont(ofSize: 20, weight: .medium)
        textField.textColor = .white
        textField.alignment = .center
        textField.placeholderString = "Type label..."
        textField.placeholderAttributedString = NSAttributedString(
            string: "Type label...",
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.4)]
        )
        textField.focusRingType = .none
        textField.delegate = self
        addSubview(textField)

        // Scroll mode key caps
        scrollContainer.orientation = .horizontal
        scrollContainer.spacing = 12
        scrollContainer.alignment = .centerY
        scrollContainer.isHidden = true

        // Create key caps: H (left), J (down), K (up), L (right)
        let keys = [("H", "←"), ("J", "↓"), ("K", "↑"), ("L", "→")]
        for (key, arrow) in keys {
            let keyCap = KeyCapView(key: key, arrow: arrow)
            keyCapViews[key.lowercased()] = keyCap
            scrollContainer.addArrangedSubview(keyCap)
        }
        addSubview(scrollContainer)

        // Hint label
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = NSColor.white.withAlphaComponent(0.5)
        hintLabel.alignment = .center
        hintLabel.stringValue = "Tab: scroll mode | ⇧: right-click"
        hintLabel.isBordered = false
        hintLabel.drawsBackground = false
        hintLabel.isEditable = false
        hintLabel.isSelectable = false
        addSubview(hintLabel)

        // Layout
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        scrollContainer.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            scrollContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            scrollContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),

            hintLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    func highlightKey(_ key: String, pressed: Bool) {
        keyCapViews[key.lowercased()]?.setPressed(pressed)
    }

    func focus() {
        window?.makeFirstResponder(textField)
    }

    func clear() {
        textField.stringValue = ""
    }

    func setMode(_ mode: InteractionMode) {
        currentMode = mode
        updateModeUI()

        if mode == .scroll {
            startKeyMonitor()
        } else {
            stopKeyMonitor()
            // Focus text field when switching back to click mode
            focus()
        }
    }

    private func updateModeUI() {
        switch currentMode {
        case .click:
            textField.isHidden = false
            scrollContainer.isHidden = true
            hintLabel.stringValue = "Tab: scroll mode | ⇧: right-click"
        case .scroll:
            textField.isHidden = true
            scrollContainer.isHidden = false
            hintLabel.stringValue = "Tab: click mode | Esc: exit"
            // Reset all key highlights
            keyCapViews.values.forEach { $0.setPressed(false) }
        }
        // Clear text when switching modes
        textField.stringValue = ""
    }

    // MARK: - Key Monitoring for Scroll Mode

    private func startKeyMonitor() {
        stopKeyMonitor()

        // Local monitor for when our app has focus (can consume events)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.currentMode == .scroll else { return event }
            return self.handleScrollKeyEvent(event, canConsume: true) ? nil : event
        }

        // Global monitor for when other apps have focus (observe only)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.currentMode == .scroll else { return }
            _ = self.handleScrollKeyEvent(event, canConsume: false)
        }
    }

    /// Handle scroll key event, returns true if handled
    private func handleScrollKeyEvent(_ event: NSEvent, canConsume: Bool) -> Bool {
        let scrollKeys = ["j", "k", "h", "l", "d", "u", "g"]
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return false }

        // Handle Tab and Escape (only in local monitor)
        if canConsume {
            if event.keyCode == 48 && event.type == .keyDown { // Tab
                onTab?()
                return true
            }
            if event.keyCode == 53 && event.type == .keyDown { // Escape
                onEscape?()
                return true
            }
        }

        guard scrollKeys.contains(chars) else { return false }

        let shift = event.modifierFlags.contains(.shift)

        if event.type == .keyDown {
            // Start continuous scrolling
            if currentScrollKey != chars {
                currentScrollKey = chars
                currentScrollShift = shift
                DispatchQueue.main.async {
                    self.highlightKey(chars, pressed: true)
                }
                onScrollKey?(chars, shift)
                startScrollTimer()
            }
            return true
        } else if event.type == .keyUp {
            // Stop continuous scrolling
            if currentScrollKey == chars {
                DispatchQueue.main.async {
                    self.highlightKey(chars, pressed: false)
                }
                stopScrollTimer()
                currentScrollKey = nil
            }
            return true
        }

        return false
    }

    private func stopKeyMonitor() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
        stopScrollTimer()
    }

    private func startScrollTimer() {
        stopScrollTimer()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self,
                  let key = self.currentScrollKey else { return }
            self.onScrollKey?(key, self.currentScrollShift)
        }
    }

    private func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
}

// MARK: - NSTextFieldDelegate

extension SearchBarView: NSTextFieldDelegate {
    func controlTextDidChange(_: Notification) {
        // In scroll mode, intercept scroll keys
        if currentMode == .scroll {
            let text = textField.stringValue
            if let lastChar = text.last {
                let key = String(lastChar)
                let scrollKeys = ["j", "k", "h", "l", "d", "u", "g"]
                if scrollKeys.contains(key.lowercased()) {
                    let shift = NSEvent.modifierFlags.contains(.shift)
                    onScrollKey?(key, shift)
                    textField.stringValue = ""
                    return
                }
            }
            // Clear any non-scroll input in scroll mode
            textField.stringValue = ""
            return
        }

        onTextChanged?(textField.stringValue)
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let shift = NSEvent.modifierFlags.contains(.shift)
            onReturn?(shift)
            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            onEscape?()
            return true
        }

        if commandSelector == #selector(NSResponder.insertTab(_:)) {
            onTab?()
            return true
        }

        return false
    }
}

// MARK: - Key Cap View

final class KeyCapView: NSView {
    private let keyLabel: NSTextField
    private let arrowLabel: NSTextField
    private var isPressed = false

    init(key: String, arrow: String) {
        keyLabel = NSTextField(labelWithString: key)
        arrowLabel = NSTextField(labelWithString: arrow)

        super.init(frame: .zero)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        updateAppearance()

        // Key label
        keyLabel.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        keyLabel.textColor = .labelColor
        keyLabel.alignment = .center
        addSubview(keyLabel)

        // Arrow label
        arrowLabel.font = .systemFont(ofSize: 10)
        arrowLabel.textColor = .secondaryLabelColor
        arrowLabel.alignment = .center
        addSubview(arrowLabel)

        // Layout
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 44),
            heightAnchor.constraint(equalToConstant: 36),

            keyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            keyLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),

            arrowLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrowLabel.topAnchor.constraint(equalTo: keyLabel.bottomAnchor, constant: -2),
        ])
    }

    func setPressed(_ pressed: Bool) {
        isPressed = pressed
        updateAppearance()
    }

    private func updateAppearance() {
        if isPressed {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            keyLabel.textColor = .white
            arrowLabel.textColor = .white.withAlphaComponent(0.8)
        } else {
            // Match Settings card background color
            layer?.backgroundColor = NSColor(red: 0x4A / 255.0, green: 0x49 / 255.0, blue: 0x49 / 255.0, alpha: 0.6)
                .cgColor
            layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
            keyLabel.textColor = .white
            arrowLabel.textColor = .white.withAlphaComponent(0.5)
        }
    }
}

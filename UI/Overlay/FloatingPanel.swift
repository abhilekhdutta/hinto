import Cocoa

/// A floating panel window that can display content above other windows
class FloatingPanel: NSPanel {
    /// If true, mouse events pass through this panel
    var isClickThrough: Bool = false {
        didSet {
            ignoresMouseEvents = isClickThrough
        }
    }

    init(contentRect: NSRect = .zero, clickThrough: Bool = false) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isClickThrough = clickThrough
        setupWindow()
    }

    private func setupWindow() {
        // Window level - above menu bar (mainMenu = 24, statusBar = 25)
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)

        // Make it transparent
        isOpaque = false
        backgroundColor = .clear

        // Don't show in dock or app switcher
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        // Set mouse event handling based on clickThrough flag
        ignoresMouseEvents = isClickThrough

        // Don't become key window
        hidesOnDeactivate = false
    }

    // Allow the panel to become key for receiving keyboard events
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Show the panel covering all screens
    func showFullScreen() {
        // Calculate the union of all screen frames
        var fullFrame = NSRect.zero
        for screen in NSScreen.screens {
            fullFrame = fullFrame.union(screen.frame)
        }

        setFrame(fullFrame, display: true)
        orderFront(nil)
    }

    /// Show the panel on a specific screen
    func show(on screen: NSScreen) {
        setFrame(screen.frame, display: true)
        orderFront(nil)
    }

    /// Hide the panel
    func hide() {
        orderOut(nil)
    }
}

import Carbon
import Cocoa

/// Manages global keyboard event monitoring using CGEventTap
final class EventTapManager {
    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Callback when the activation hotkey is pressed
    var onHotKeyPressed: (() -> Void)?

    /// Callback for key events during active mode
    var onKeyEvent: ((KeyEvent) -> Bool)?

    /// The hotkey configuration (default: Cmd+Shift+Space)
    var hotKey: HotKey = .init(
        keyCode: UInt16(kVK_Space),
        modifiers: [.command, .shift]
    )

    /// Whether the event tap is currently active
    private(set) var isRunning = false

    deinit {
        stop()
    }

    /// Start listening for keyboard events
    func start() {
        guard !isRunning else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        // Check accessibility first
        let trusted = AXIsProcessTrusted()
        log("EventTapManager: AXIsProcessTrusted = \(trusted)")

        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            log("EventTapManager: Failed to create event tap. AXIsProcessTrusted=\(trusted)")
            return
        }

        eventTap = tap

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        log("EventTapManager: Started")
    }

    /// Stop listening for keyboard events
    func stop() {
        guard isRunning else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false
        log("EventTapManager: Stopped")
    }

    /// Handle keyboard event
    fileprivate func handleEvent(_ event: CGEvent, type: CGEventType) -> CGEvent? {
        // Check for hotkey
        if type == .keyDown {
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags

            if isHotKeyMatch(keyCode: keyCode, flags: flags) {
                onHotKeyPressed?()
                return nil // Consume the event
            }
        }

        // Forward to key event handler if set
        if let handler = onKeyEvent {
            let keyEvent = KeyEvent(from: event, type: type)
            if handler(keyEvent) {
                return nil // Consume the event
            }
        }

        return event
    }

    private func isHotKeyMatch(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        guard keyCode == hotKey.keyCode else { return false }

        let requiredFlags = hotKey.modifiers
        let hasCommand = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        return hasCommand == requiredFlags.contains(.command) &&
            hasShift == requiredFlags.contains(.shift) &&
            hasControl == requiredFlags.contains(.control) &&
            hasOption == requiredFlags.contains(.option)
    }
}

// MARK: - Event Tap Callback

private func eventTapCallback(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle special cases
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        // Re-enable the tap
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    if let resultEvent = manager.handleEvent(event, type: type) {
        return Unmanaged.passUnretained(resultEvent)
    }

    return nil
}

// MARK: - Supporting Types

struct HotKey {
    var keyCode: UInt16
    var modifiers: ModifierFlags

    struct ModifierFlags: OptionSet {
        let rawValue: UInt

        static let command = ModifierFlags(rawValue: 1 << 0)
        static let shift = ModifierFlags(rawValue: 1 << 1)
        static let control = ModifierFlags(rawValue: 1 << 2)
        static let option = ModifierFlags(rawValue: 1 << 3)
    }
}

struct KeyEvent {
    let keyCode: UInt16
    let character: String?
    let isKeyDown: Bool
    let modifiers: KeyModifiers

    struct KeyModifiers: OptionSet {
        let rawValue: UInt

        static let command = KeyModifiers(rawValue: 1 << 0)
        static let shift = KeyModifiers(rawValue: 1 << 1)
        static let control = KeyModifiers(rawValue: 1 << 2)
        static let option = KeyModifiers(rawValue: 1 << 3)
    }

    init(from event: CGEvent, type: CGEventType) {
        keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        isKeyDown = type == .keyDown

        // Get character
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        character = length > 0 ? String(utf16CodeUnits: chars, count: length) : nil

        // Get modifiers
        let flags = event.flags
        var mods: KeyModifiers = []
        if flags.contains(.maskCommand) { mods.insert(.command) }
        if flags.contains(.maskShift) { mods.insert(.shift) }
        if flags.contains(.maskControl) { mods.insert(.control) }
        if flags.contains(.maskAlternate) { mods.insert(.option) }
        modifiers = mods
    }
}

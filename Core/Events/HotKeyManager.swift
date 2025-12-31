import Carbon
import Cocoa

/// Manages global hotkey registration using Carbon Hot Key API
/// Alternative to EventTapManager for simpler hotkey-only use cases
final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    /// Callback when the hotkey is pressed
    var onHotKeyPressed: (() -> Void)?

    /// The registered hotkey ID
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D4C_5353), id: 1) // 'MLSS'

    deinit {
        unregister()
    }

    /// Register a global hotkey
    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        // Unregister existing hotkey first
        unregister()

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            print("HotKeyManager: Failed to install event handler: \(status)")
            return false
        }

        // Register hotkey
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            print("HotKeyManager: Failed to register hotkey: \(registerStatus)")
            return false
        }

        print("HotKeyManager: Registered hotkey")
        return true
    }

    /// Register with default Cmd+Shift+Space
    func registerDefault() -> Bool {
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_Space)
        return register(keyCode: keyCode, modifiers: modifiers)
    }

    /// Unregister the hotkey
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    /// Handle hotkey event
    fileprivate func handleHotKey() {
        onHotKeyPressed?()
    }
}

// MARK: - Event Handler Callback

private func hotKeyEventHandler(
    nextHandler _: EventHandlerCallRef?,
    event _: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKey()

    return noErr
}

// MARK: - Key Code Constants

extension HotKeyManager {
    /// Common key codes for hotkey registration
    enum KeyCode {
        static let space = UInt32(kVK_Space)
        static let returnKey = UInt32(kVK_Return)
        static let escape = UInt32(kVK_Escape)
        static let tab = UInt32(kVK_Tab)

        // Letters
        static let a = UInt32(kVK_ANSI_A)
        static let s = UInt32(kVK_ANSI_S)
        static let d = UInt32(kVK_ANSI_D)
        static let f = UInt32(kVK_ANSI_F)
        static let j = UInt32(kVK_ANSI_J)
        static let k = UInt32(kVK_ANSI_K)
        static let l = UInt32(kVK_ANSI_L)
    }

    /// Modifier key masks
    enum Modifier {
        static let command = UInt32(cmdKey)
        static let shift = UInt32(shiftKey)
        static let option = UInt32(optionKey)
        static let control = UInt32(controlKey)
    }
}

import Carbon
import Cocoa

/// Manages input source (keyboard layout) switching
final class InputSourceManager {
    static let shared = InputSourceManager()

    private var savedInputSource: TISInputSource?

    private init() {}

    /// Get the current input source
    var currentInputSource: TISInputSource? {
        TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    /// Get the input source ID
    var currentInputSourceID: String? {
        guard let source = currentInputSource else { return nil }
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }

    /// Save the current input source for later restoration
    func saveCurrentInputSource() {
        savedInputSource = currentInputSource
    }

    /// Restore the previously saved input source
    func restoreSavedInputSource() {
        guard let source = savedInputSource else { return }
        TISSelectInputSource(source)
        savedInputSource = nil
    }

    /// Switch to ASCII-capable input source (for typing labels)
    func switchToASCII() {
        guard let sources = TISCreateASCIICapableInputSourceList()?.takeRetainedValue() as? [TISInputSource],
              let asciiSource = sources.first
        else {
            return
        }

        TISSelectInputSource(asciiSource)
    }

    /// Switch to a specific input source by ID
    func switchTo(inputSourceID: String) -> Bool {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }

        for source in sources {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String

            if sourceID == inputSourceID {
                TISSelectInputSource(source)
                return true
            }
        }

        return false
    }

    /// Get list of all enabled input sources
    func enabledInputSources() -> [(id: String, name: String)] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        var result: [(id: String, name: String)] = []

        for source in sources {
            // Check if it's a keyboard input source
            guard let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else { continue }
            let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue() as String
            guard category == kTISCategoryKeyboardInputSource as String else { continue }

            // Check if it's enabled
            guard let enabledPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { continue }
            let enabled = Unmanaged<CFBoolean>.fromOpaque(enabledPtr).takeUnretainedValue()
            guard CFBooleanGetValue(enabled) else { continue }

            // Get ID and name
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                  let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { continue }

            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String

            result.append((id: id, name: name))
        }

        return result
    }
}

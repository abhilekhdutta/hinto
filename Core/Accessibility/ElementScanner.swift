import ApplicationServices
import Cocoa

/// Protocol for scanning UI elements from accessibility hierarchy
protocol ElementScanner {
    /// Scan and return UI elements
    /// - Parameter context: Scanning context with window and app info
    /// - Returns: Array of discovered UI elements
    func scan(context: ScanContext) -> [UIElement]
}

/// Context for element scanning operations
struct ScanContext {
    let appElement: AXUIElement
    let focusedWindow: AXUIElement?
    let windowFrame: CGRect?

    init(appElement: AXUIElement, focusedWindow: AXUIElement? = nil) {
        self.appElement = appElement
        self.focusedWindow = focusedWindow
        windowFrame = focusedWindow?.frame
    }
}

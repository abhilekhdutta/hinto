import ApplicationServices
import Cocoa

/// Builds a UITree by coordinating element scanners
final class UITreeBuilder {
    private let searchPredicateScanner: ElementScanner
    private let treeTraversalScanner: ElementScanner
    private let hitTestScanner: ElementScanner
    private let menuBarScanner: ElementScanner

    init(
        searchPredicateScanner: ElementScanner = SearchPredicateScanner(),
        treeTraversalScanner: ElementScanner = TreeTraversalScanner(),
        hitTestScanner: ElementScanner = HitTestScanner(),
        menuBarScanner: ElementScanner = MenuBarScanner()
    ) {
        self.searchPredicateScanner = searchPredicateScanner
        self.treeTraversalScanner = treeTraversalScanner
        self.hitTestScanner = hitTestScanner
        self.menuBarScanner = menuBarScanner
    }

    /// Build a UITree for the frontmost application's focused window
    func buildTree() -> UITree {
        let tree = UITree()

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("UITreeBuilder: No frontmost application")
            return tree
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        let focusedWindow = getFocusedWindow(from: appElement)

        let context = ScanContext(appElement: appElement, focusedWindow: focusedWindow)

        // Try search predicates first (fastest)
        var elements = searchPredicateScanner.scan(context: context)

        // Fallback to tree traversal if search predicate returns empty
        if elements.isEmpty {
            elements = treeTraversalScanner.scan(context: context)
        }

        tree.allElements = elements
        return tree
    }

    /// Build a UITree for the focused window with all scanning strategies
    func buildTreeForAllScreens() -> UITree {
        log("UITreeBuilder: buildTreeForAllScreens start")
        let tree = UITree()

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            log("UITreeBuilder: No frontmost application")
            return tree
        }

        log("UITreeBuilder: Scanning \(frontmostApp.localizedName ?? "unknown")")
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        let focusedWindow = getFocusedWindow(from: appElement)

        guard focusedWindow != nil else {
            log("UITreeBuilder: No focused window found")
            return tree
        }

        let context = ScanContext(appElement: appElement, focusedWindow: focusedWindow)
        var allElements: [UIElement] = []

        // Primary scan: search predicates (fastest)
        var windowElements = searchPredicateScanner.scan(context: context)
        log("UITreeBuilder: Search predicate found \(windowElements.count) elements")

        // Fallback: tree traversal if search predicate fails
        if windowElements.isEmpty {
            log("UITreeBuilder: Search predicate empty, using tree traversal")
            windowElements = treeTraversalScanner.scan(context: context)
            log("UITreeBuilder: Tree traversal found \(windowElements.count) elements")
        }

        allElements.append(contentsOf: windowElements)

        // Additional: hit-test scanning for tabs, sidebars, tool windows
        let hitTestElements = hitTestScanner.scan(context: context)
        log("UITreeBuilder: Hit-test found \(hitTestElements.count) additional elements")
        allElements.append(contentsOf: hitTestElements)

        // Menu bar scanning (system-wide)
        log("UITreeBuilder: Scanning menu bar...")
        let menuElements = menuBarScanner.scan(context: context)
        log("UITreeBuilder: Menu bar found \(menuElements.count) elements")
        allElements.append(contentsOf: menuElements)

        tree.allElements = allElements
        log("UITreeBuilder: Done, total \(allElements.count) elements")
        return tree
    }

    // MARK: - Private Methods

    /// Get the focused window from an application element
    private func getFocusedWindow(from appElement: AXUIElement) -> AXUIElement? {
        // Try to get focused window first
        var focusedWindowRef: CFTypeRef?
        let focusedError = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowRef
        )

        if focusedError == .success, let focusedWindow = focusedWindowRef {
            return (focusedWindow as! AXUIElement)
        }

        // Fallback: try to get the first window if no focused window
        var windowsRef: CFTypeRef?
        let windowsError = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        if windowsError == .success, let windows = windowsRef as? [AXUIElement], let firstWindow = windows.first {
            return firstWindow
        }

        return nil
    }
}

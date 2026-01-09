import ApplicationServices
import Cocoa

/// Scans menu bar items and menu bar extras (system tray icons)
final class MenuBarScanner: ElementScanner {
    private let systemWide = AXUIElementCreateSystemWide()

    func scan(context: ScanContext) -> [UIElement] {
        var results: [UIElement] = []

        // Scan menu bar items
        if let menuItems = scanMenuBar(appElement: context.appElement) {
            results.append(contentsOf: menuItems)
        }

        // Scan menu bar extras (right side icons)
        if let extras = scanMenuBarExtras() {
            results.append(contentsOf: extras)
        }

        return results
    }

    // MARK: - Menu Bar

    private func scanMenuBar(appElement: AXUIElement) -> [UIElement]? {
        var menuBar: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)

        guard error == .success, let menuBar = menuBar else {
            log("MenuBarScanner: Could not get menu bar, error: \(error.rawValue)")
            return nil
        }

        return getMenuBarItems(from: (menuBar as! AXUIElement))
    }

    private func getMenuBarItems(from menuBar: AXUIElement) -> [UIElement] {
        var results: [UIElement] = []

        guard let children = menuBar.children else { return results }

        for child in children {
            let element = UIElement(axElement: child)
            if element.frame.width > 0 && element.frame.height > 0 {
                results.append(element)
            }
        }

        return results
    }

    // MARK: - Menu Bar Extras

    private func scanMenuBarExtras() -> [UIElement]? {
        var results: [UIElement] = []

        guard let mainScreen = NSScreen.main else { return nil }

        let menuBarY: CGFloat = 12
        let screenWidth = mainScreen.frame.width
        var scannedElements: Set<String> = []

        for x in stride(from: screenWidth - 50, through: screenWidth / 2, by: -30) {
            var elementRef: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(systemWide, Float(x), Float(menuBarY), &elementRef)

            guard error == .success, let element = elementRef else { continue }

            var posRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success else {
                continue
            }

            var pos = CGPoint.zero
            AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
            let posKey = "\(Int(pos.x)),\(Int(pos.y))"

            if scannedElements.contains(posKey) { continue }
            scannedElements.insert(posKey)

            let role = element.role ?? "Unknown"
            if role == "AXMenuBarItem" || role == "AXButton" || role == "AXMenuButton" {
                let estimatedFrame = CGRect(x: pos.x, y: pos.y, width: 28, height: 22)
                let uiElement = UIElement(axElement: element, customFrame: estimatedFrame)
                results.append(uiElement)
            }
        }

        return results.isEmpty ? nil : results
    }
}

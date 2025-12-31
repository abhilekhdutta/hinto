import ApplicationServices
import Cocoa

/// Builds a UITree by scanning the accessibility hierarchy
final class UITreeBuilder {
    /// Search keys for finding specific UI element types quickly
    private static let searchKeys: [String] = [
        "AXButtonSearchKey",
        "AXCheckBoxSearchKey",
        "AXControlSearchKey",
        "AXLinkSearchKey",
        "AXTextFieldSearchKey",
        "AXMenuItemSearchKey",
        "AXTabGroupSearchKey",
        "AXRadioGroupSearchKey",
        "AXOutlineSearchKey",
        "AXGraphicSearchKey",
        "AXKeyboardFocusableSearchKey",
    ]

    /// Build a UITree for the frontmost application's focused window
    func buildTree() -> UITree {
        let tree = UITree()

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("UITreeBuilder: No frontmost application")
            return tree
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        guard let focusedWindow = getFocusedWindow(from: appElement) else {
            print("UITreeBuilder: No focused window")
            return tree
        }

        // Try using search predicates first (faster for supported apps)
        var elements = scanWindow(focusedWindow)

        // Fallback to tree traversal if search predicate returns empty
        if elements.isEmpty {
            elements = traverseTree(from: focusedWindow)
        }

        tree.allElements = elements
        return tree
    }

    /// Build a UITree for the focused window only
    func buildTreeForAllScreens() -> UITree {
        log("UITreeBuilder: buildTreeForAllScreens start")
        let tree = UITree()
        var allElements: [UIElement] = []

        // Scan frontmost app's focused window only
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            log("UITreeBuilder: Scanning \(frontmostApp.localizedName ?? "unknown")")
            let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

            // Get focused window
            if let focusedWindow = getFocusedWindow(from: appElement) {
                // Try search predicate first (faster)
                var elements = scanWindow(focusedWindow)

                // Fallback to tree traversal if search predicate fails
                if elements.isEmpty {
                    log("UITreeBuilder: Search predicate empty, using tree traversal")
                    elements = traverseTree(from: focusedWindow, maxElements: 1500)
                }

                // Additionally scan specific areas using hit-testing
                if let windowFrame = focusedWindow.frame {
                    var additionalElements: [UIElement] = []

                    // Scan key y positions where tabs are found
                    // IntelliJ tabs: y=58-65 for tab labels, y=64 for tab names
                    let tabYPositions = [58, 65, 72]
                    for y in tabYPositions {
                        let found = scanAreaWithHitTest(
                            startX: Int(windowFrame.origin.x) + 30,
                            endX: Int(windowFrame.origin.x + windowFrame.width) - 30,
                            y: y,
                            stepX: 8
                        )
                        additionalElements.append(contentsOf: found)
                    }

                    // Scan bottom toolbar area (IntelliJ status bar with Git, TODO, etc.)
                    let windowBottom = Int(windowFrame.origin.y + windowFrame.height)
                    // Bottom toolbar is typically in the last 30-50 pixels of the window
                    let bottomYPositions = [
                        windowBottom - 15,
                        windowBottom - 25,
                        windowBottom - 35,
                    ]
                    for y in bottomYPositions {
                        let found = scanAreaWithHitTest(
                            startX: Int(windowFrame.origin.x),
                            endX: Int(windowFrame.origin.x + windowFrame.width),
                            y: y,
                            stepX: 20
                        )
                        additionalElements.append(contentsOf: found)
                    }

                    // Scan left sidebar toolbar (vertical icons)
                    let leftXPositions = [
                        Int(windowFrame.origin.x) + 15,
                        Int(windowFrame.origin.x) + 35,
                    ]
                    for x in leftXPositions {
                        let found = scanVerticalAreaWithHitTest(
                            x: x,
                            startY: Int(windowFrame.origin.y) + 100,
                            endY: windowBottom - 50,
                            stepY: 25
                        )
                        additionalElements.append(contentsOf: found)
                    }

                    log("UITreeBuilder: Hit-test found \(additionalElements.count) additional elements")
                    elements.append(contentsOf: additionalElements)
                }

                log("UITreeBuilder: App elements: \(elements.count)")
                allElements.append(contentsOf: elements)
            } else {
                log("UITreeBuilder: No focused window found")
            }
        }

        // Scan menu bar (system-wide)
        log("UITreeBuilder: Scanning menu bar...")
        if let menuElements = scanMenuBar() {
            log("UITreeBuilder: Menu bar elements: \(menuElements.count)")
            allElements.append(contentsOf: menuElements)
        }

        // Scan menu bar extras (right side icons)
        log("UITreeBuilder: Scanning menu extras...")
        if let extraElements = scanMenuBarExtras() {
            log("UITreeBuilder: Menu extras: \(extraElements.count)")
            allElements.append(contentsOf: extraElements)
        }

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

    /// Scan a single window for UI elements
    private func scanWindow(_ window: AXUIElement) -> [UIElement] {
        var results: [UIElement] = []

        // Use search predicate for each search key
        for searchKey in Self.searchKeys {
            if let elements = performSearch(in: window, searchKey: searchKey) {
                for axElement in elements {
                    let uiElement = UIElement(axElement: axElement)
                    if uiElement.frame.width > 0 && uiElement.frame.height > 0 {
                        results.append(uiElement)
                    }
                }
            }
        }

        return results
    }

    /// Perform accessibility search using search key
    private func performSearch(in element: AXUIElement, searchKey: String) -> [AXUIElement]? {
        var searchResults: CFTypeRef?

        // Create search predicate with deep search
        let searchPredicate: [String: Any] = [
            "AXSearchKey": searchKey,
            "AXDirection": "AXDirectionNext",
            "AXResultsLimit": 200,
            "AXImmediateDescendantsOnly": false,
            "AXVisibleOnly": true,
        ]

        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            "AXUIElementsForSearchPredicate" as CFString,
            searchPredicate as CFTypeRef,
            &searchResults
        )

        if error == .success, let results = searchResults as? [AXUIElement] {
            return results
        }

        return nil
    }

    /// Traverse the accessibility tree recursively with limits
    private func traverseTree(from element: AXUIElement, depth: Int = 0, maxElements: Int = 1000) -> [UIElement] {
        var results: [UIElement] = []

        // Limit depth to prevent infinite recursion (increased for Electron apps)
        guard depth < 30 else { return results }

        let uiElement = UIElement(axElement: element)

        // Add this element if it has a valid frame
        if uiElement.frame.width > 0 && uiElement.frame.height > 0 {
            results.append(uiElement)
        }

        // Stop if we have enough elements
        guard results.count < maxElements else { return results }

        // Traverse children (removed children count limit for Electron apps)
        if let children = element.children {
            // Limit to first 200 children to avoid extremely wide trees
            let limitedChildren = children.prefix(200)
            for child in limitedChildren {
                let remaining = maxElements - results.count
                guard remaining > 0 else { break }

                let childElements = traverseTree(from: child, depth: depth + 1, maxElements: remaining)
                results.append(contentsOf: childElements)
            }
        }

        return results
    }

    /// Scan the menu bar for menu items
    private func scanMenuBar() -> [UIElement]? {
        // Get frontmost app's menu bar
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            log("UITreeBuilder: No frontmost app for menu bar")
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var menuBar: CFTypeRef?
        let menuError = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)

        guard menuError == .success, let menuBarElement = menuBar else {
            log("UITreeBuilder: Could not get menu bar, error: \(menuError.rawValue)")
            return nil
        }

        // Get direct children (menu bar items)
        let items = getMenuBarItems(from: menuBarElement as! AXUIElement)
        log("UITreeBuilder: Menu bar has \(items.count) items")
        return items
    }

    /// Get menu bar items (shallow scan)
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

    /// Scan a horizontal area using hit-testing to find clickable elements
    private func scanAreaWithHitTest(startX: Int, endX: Int, y: Int, stepX: Int) -> [UIElement] {
        var results: [UIElement] = []
        var scannedPositions: Set<String> = []
        var processedTabGroups: Set<String> = [] // Track tab groups we've already enumerated
        let systemWide = AXUIElementCreateSystemWide()

        for x in stride(from: startX, through: endX, by: stepX) {
            var elementRef: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(systemWide, Float(x), Float(y), &elementRef)

            if error == .success, let element = elementRef {
                // Get actual position and size
                guard let pos = element.position, let size = element.size else { continue }

                // Create unique key based on position
                let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                if scannedPositions.contains(posKey) { continue }
                scannedPositions.insert(posKey)

                let role = element.role ?? "Unknown"

                // For tabs, prefer AXRadioButton (actual tab) over small AXButton (close button)
                // Skip small buttons that are likely close buttons or icons within tabs
                if role == "AXButton" && (size.width < 30 || size.height < 30) {
                    continue
                }

                // Only include clickable roles with minimum size
                let clickableRoles: Set<String> = ["AXTab", "AXRadioButton", "AXCell", "AXLink"]
                // Also include larger buttons (not close buttons)
                let isLargeButton = role == "AXButton" && size.width >= 30 && size.height >= 30
                // Include AXStaticText in tab bar area (y=55-90) as they represent tab labels in IntelliJ
                let isTabLabel = role == "AXStaticText" && pos.y >= 55 && pos.y <= 90 && size.width >= 50

                if (clickableRoles.contains(role) || isLargeButton || isTabLabel) && size.width > 10 && size
                    .height > 10
                {
                    let frame = CGRect(origin: pos, size: size)
                    let uiElement = UIElement(axElement: element, customFrame: frame)
                    results.append(uiElement)

                    // For tab elements, try to find sibling tabs through parent
                    if role == "AXRadioButton" || role == "AXTab" {
                        let siblingTabs = findSiblingTabs(
                            for: element,
                            processedGroups: &processedTabGroups,
                            scannedPositions: &scannedPositions
                        )
                        results.append(contentsOf: siblingTabs)
                    }
                }
            }
        }

        return results
    }

    /// Scan a vertical area using hit-testing to find clickable elements (for sidebars)
    private func scanVerticalAreaWithHitTest(x: Int, startY: Int, endY: Int, stepY: Int) -> [UIElement] {
        var results: [UIElement] = []
        var scannedPositions: Set<String> = []
        let systemWide = AXUIElementCreateSystemWide()

        for y in stride(from: startY, through: endY, by: stepY) {
            var elementRef: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(systemWide, Float(x), Float(y), &elementRef)

            if error == .success, let element = elementRef {
                guard let pos = element.position, let size = element.size else { continue }

                let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                if scannedPositions.contains(posKey) { continue }
                scannedPositions.insert(posKey)

                let role = element.role ?? "Unknown"

                // Include buttons and other clickable elements in sidebar
                let clickableRoles: Set<String> = ["AXButton", "AXRadioButton", "AXCell", "AXLink", "AXStaticText"]
                if clickableRoles.contains(role) && size.width > 10 && size.height > 10 {
                    let frame = CGRect(origin: pos, size: size)
                    let uiElement = UIElement(axElement: element, customFrame: frame)
                    results.append(uiElement)
                }
            }
        }

        return results
    }

    /// Find sibling tabs by traversing up to parent tab group
    private func findSiblingTabs(
        for tabElement: AXUIElement,
        processedGroups: inout Set<String>,
        scannedPositions: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []

        // Get parent element
        guard let parent = tabElement.parent else {
            log("UITreeBuilder: Tab has no parent")
            return results
        }

        // Get parent position as unique key
        if let parentPos = parent.position {
            let parentKey = "\(Int(parentPos.x)),\(Int(parentPos.y))"
            if processedGroups.contains(parentKey) {
                return results // Already processed this tab group
            }
            processedGroups.insert(parentKey)
        }

        // Try to get tabs from parent (works for AXTabGroup in native apps, not Java)
        if let tabs = parent.tabs {
            for tab in tabs {
                if let pos = tab.position, let size = tab.size {
                    let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                    if !scannedPositions.contains(posKey) && size.width > 10 && size.height > 10 {
                        scannedPositions.insert(posKey)
                        let frame = CGRect(origin: pos, size: size)
                        let uiElement = UIElement(axElement: tab, customFrame: frame)
                        results.append(uiElement)
                    }
                }
            }
        }

        // Also try children (for AXRadioGroup or other containers)
        if let children = parent.children {
            for child in children {
                let childRole = child.role ?? "Unknown"
                // Only add tab-like children
                if childRole == "AXRadioButton" || childRole == "AXTab" {
                    if let pos = child.position, let size = child.size {
                        let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                        if !scannedPositions.contains(posKey) && size.width > 10 && size.height > 10 {
                            scannedPositions.insert(posKey)
                            let frame = CGRect(origin: pos, size: size)
                            let uiElement = UIElement(axElement: child, customFrame: frame)
                            results.append(uiElement)
                        }
                    }
                }
            }
        }

        return results
    }

    /// Scan menu bar extras (system tray icons on the right)
    private func scanMenuBarExtras() -> [UIElement]? {
        var results: [UIElement] = []

        // Use system-wide element to find all menu bar items
        let systemWide = AXUIElementCreateSystemWide()

        // Get the element at the menu bar location (top of screen)
        if let mainScreen = NSScreen.main {
            // Menu bar is at the very top - scan across the right side
            let menuBarY: CGFloat = 12 // Middle of menu bar
            let screenWidth = mainScreen.frame.width

            // Sample points across the right side of the menu bar (where extras live)
            var scannedElements: Set<String> = [] // Track by position to avoid duplicates

            for x in stride(from: screenWidth - 50, through: screenWidth / 2, by: -30) {
                let point = CGPoint(x: x, y: menuBarY)
                var elementRef: AXUIElement?
                let error = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &elementRef)

                if error == .success, let element = elementRef {
                    // Get position to check for duplicates
                    var posRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success {
                        var pos = CGPoint.zero
                        AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
                        let posKey = "\(Int(pos.x)),\(Int(pos.y))"

                        if !scannedElements.contains(posKey) {
                            scannedElements.insert(posKey)

                            // Create UIElement with estimated frame
                            let role = element.role ?? "Unknown"
                            if role == "AXMenuBarItem" || role == "AXButton" || role == "AXMenuButton" {
                                // Estimate size: menu bar height is ~24, width varies
                                let estimatedFrame = CGRect(x: pos.x, y: pos.y, width: 28, height: 22)
                                let uiElement = UIElement(axElement: element, customFrame: estimatedFrame)
                                results.append(uiElement)
                                log("UITreeBuilder: Found menu extra at (\(Int(pos.x)), \(Int(pos.y))) role=\(role)")
                            }
                        }
                    }
                }
            }
        }

        log("UITreeBuilder: Total menu extras found: \(results.count)")
        return results.isEmpty ? nil : results
    }
}

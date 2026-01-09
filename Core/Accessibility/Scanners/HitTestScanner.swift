import ApplicationServices
import Cocoa

/// Scans UI elements using hit-testing at specific screen positions
/// Used for tabs, sidebars, and tool windows that search predicates may miss
final class HitTestScanner: ElementScanner {
    private let systemWide = AXUIElementCreateSystemWide()

    func scan(context: ScanContext) -> [UIElement] {
        guard let windowFrame = context.windowFrame else { return [] }

        var results: [UIElement] = []
        var scannedPositions: Set<String> = []
        var processedTabGroups: Set<String> = []

        // Scan title bar and toolbar region for tabs
        results.append(contentsOf: scanTabs(
            windowFrame: windowFrame,
            scannedPositions: &scannedPositions,
            processedTabGroups: &processedTabGroups
        ))

        // Scan bottom toolbar (IntelliJ status bar)
        results.append(contentsOf: scanBottomToolbar(
            windowFrame: windowFrame,
            scannedPositions: &scannedPositions
        ))

        // Scan tool window panels (Terminal/Run/Debug session tabs)
        results.append(contentsOf: scanToolWindows(
            windowFrame: windowFrame,
            scannedPositions: &scannedPositions,
            processedTabGroups: &processedTabGroups
        ))

        // Scan left sidebar
        results.append(contentsOf: scanLeftSidebar(
            windowFrame: windowFrame,
            scannedPositions: &scannedPositions
        ))

        return results
    }

    // MARK: - Scanning Regions

    private func scanTabs(
        windowFrame: CGRect,
        scannedPositions: inout Set<String>,
        processedTabGroups: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        // Scan title bar and toolbar region at regular intervals
        // Covers tabs and toolbar buttons regardless of specific app layout
        let tabYPositions = stride(from: 20, through: 80, by: 8).map { $0 }

        for y in tabYPositions {
            let found = scanHorizontalArea(
                startX: Int(windowFrame.origin.x) + 30,
                endX: Int(windowFrame.origin.x + windowFrame.width) - 30,
                y: y,
                stepX: 15,
                scannedPositions: &scannedPositions,
                processedTabGroups: &processedTabGroups
            )
            results.append(contentsOf: found)
        }

        return results
    }

    private func scanBottomToolbar(
        windowFrame: CGRect,
        scannedPositions: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        let windowBottom = Int(windowFrame.origin.y + windowFrame.height)
        let bottomYPositions = [windowBottom - 15, windowBottom - 25, windowBottom - 35]
        var processedTabGroups: Set<String> = []

        for y in bottomYPositions {
            let found = scanHorizontalArea(
                startX: Int(windowFrame.origin.x),
                endX: Int(windowFrame.origin.x + windowFrame.width),
                y: y,
                stepX: 20,
                scannedPositions: &scannedPositions,
                processedTabGroups: &processedTabGroups
            )
            results.append(contentsOf: found)
        }

        return results
    }

    private func scanToolWindows(
        windowFrame: CGRect,
        scannedPositions: inout Set<String>,
        processedTabGroups: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        let windowTop = Int(windowFrame.origin.y)
        let windowBottom = Int(windowFrame.origin.y + windowFrame.height)
        let windowHeight = windowBottom - windowTop

        // Strategic heights: 40%, 50%, 60%, 70%, 80% of window
        let toolWindowYPositions = [
            windowTop + (windowHeight * 40 / 100),
            windowTop + (windowHeight * 50 / 100),
            windowTop + (windowHeight * 60 / 100),
            windowTop + (windowHeight * 70 / 100),
            windowTop + (windowHeight * 80 / 100),
        ]

        for y in toolWindowYPositions {
            let found = scanHorizontalArea(
                startX: Int(windowFrame.origin.x) + 50,
                endX: Int(windowFrame.origin.x + windowFrame.width) - 50,
                y: y,
                stepX: 30,
                scannedPositions: &scannedPositions,
                processedTabGroups: &processedTabGroups
            )
            results.append(contentsOf: found)
        }

        return results
    }

    private func scanLeftSidebar(
        windowFrame: CGRect,
        scannedPositions: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        let windowBottom = Int(windowFrame.origin.y + windowFrame.height)
        let leftXPositions = [
            Int(windowFrame.origin.x) + 15,
            Int(windowFrame.origin.x) + 35,
        ]

        for x in leftXPositions {
            let found = scanVerticalArea(
                x: x,
                startY: Int(windowFrame.origin.y) + 100,
                endY: windowBottom - 50,
                stepY: 25,
                scannedPositions: &scannedPositions
            )
            results.append(contentsOf: found)
        }

        return results
    }

    // MARK: - Core Scanning Methods

    private func scanHorizontalArea(
        startX: Int,
        endX: Int,
        y: Int,
        stepX: Int,
        scannedPositions: inout Set<String>,
        processedTabGroups: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        var x = startX

        while x <= endX {
            var elementRef: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(systemWide, Float(x), Float(y), &elementRef)

            guard error == .success, let element = elementRef else {
                x += stepX
                continue
            }
            guard let pos = element.position, let size = element.size else {
                x += stepX
                continue
            }

            let posKey = "\(Int(pos.x)),\(Int(pos.y))"
            if scannedPositions.contains(posKey) {
                // Already scanned this element, jump past it
                let jumpDistance = max(stepX, Int(pos.x + size.width) - x + 1)
                x += jumpDistance
                continue
            }
            scannedPositions.insert(posKey)

            let role = element.role ?? "Unknown"

            // Skip small buttons (likely close buttons within tabs)
            if role == "AXButton" && (size.width < 30 || size.height < 30) {
                x += stepX
                continue
            }

            if shouldIncludeElement(role: role, position: pos, size: size) {
                let frame = CGRect(origin: pos, size: size)
                let uiElement = UIElement(axElement: element, customFrame: frame)
                results.append(uiElement)

                // Find sibling tabs if this is a tab element
                if role == "AXRadioButton" || role == "AXTab" {
                    let siblings = findSiblingTabs(
                        for: element,
                        processedGroups: &processedTabGroups,
                        scannedPositions: &scannedPositions
                    )
                    results.append(contentsOf: siblings)
                }

                // Jump past this element (jump to element's right edge + 1)
                let jumpTo = Int(pos.x + size.width) + 1
                x = max(x + stepX, jumpTo)
            } else {
                x += stepX
            }
        }

        return results
    }

    private func scanVerticalArea(
        x: Int,
        startY: Int,
        endY: Int,
        stepY: Int,
        scannedPositions: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []
        var y = startY

        while y <= endY {
            var elementRef: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(systemWide, Float(x), Float(y), &elementRef)

            guard error == .success, let element = elementRef else {
                y += stepY
                continue
            }
            guard let pos = element.position, let size = element.size else {
                y += stepY
                continue
            }

            let posKey = "\(Int(pos.x)),\(Int(pos.y))"
            if scannedPositions.contains(posKey) {
                // Already scanned this element, jump past it
                let jumpDistance = max(stepY, Int(pos.y + size.height) - y + 1)
                y += jumpDistance
                continue
            }
            scannedPositions.insert(posKey)

            let role = element.role ?? "Unknown"
            let sidebarRoles: Set<String> = ["AXButton", "AXRadioButton", "AXCell", "AXLink", "AXStaticText"]

            if sidebarRoles.contains(role) && size.width > 10 && size.height > 10 {
                let frame = CGRect(origin: pos, size: size)
                let uiElement = UIElement(axElement: element, customFrame: frame)
                results.append(uiElement)

                // Jump past this element (jump to element's bottom edge + 1)
                let jumpTo = Int(pos.y + size.height) + 1
                y = max(y + stepY, jumpTo)
            } else {
                y += stepY
            }
        }

        return results
    }

    // MARK: - Element Classification

    private func shouldIncludeElement(role: String, position: CGPoint, size: CGSize) -> Bool {
        let clickableRoles: Set<String> = ["AXTab", "AXRadioButton", "AXCell", "AXLink"]

        // Large buttons (not close buttons)
        let isLargeButton = role == "AXButton" && size.width >= 30 && size.height >= 30

        // File tab labels (y=55-90, width >= 50)
        let isFileTabLabel = role == "AXStaticText" && position.y >= 55 && position.y <= 90 && size.width >= 50

        // Session tabs (y > 100, width 30-200)
        let isToolWindowTab = role == "AXStaticText" && position.y > 100 && size.width >= 30 && size.width <= 200

        let isTabLabel = isFileTabLabel || isToolWindowTab

        return (clickableRoles.contains(role) || isLargeButton || isTabLabel)
            && size.width > 10 && size.height > 10
    }

    // MARK: - Tab Group Discovery

    private func findSiblingTabs(
        for tabElement: AXUIElement,
        processedGroups: inout Set<String>,
        scannedPositions: inout Set<String>
    ) -> [UIElement] {
        var results: [UIElement] = []

        guard let parent = tabElement.parent else { return results }

        // Track processed tab groups by position
        if let parentPos = parent.position {
            let parentKey = "\(Int(parentPos.x)),\(Int(parentPos.y))"
            if processedGroups.contains(parentKey) { return results }
            processedGroups.insert(parentKey)
        }

        // Try tabs attribute (AXTabGroup)
        if let tabs = parent.tabs {
            for tab in tabs {
                if let pos = tab.position, let size = tab.size {
                    let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                    if !scannedPositions.contains(posKey) && size.width > 10 && size.height > 10 {
                        scannedPositions.insert(posKey)
                        let frame = CGRect(origin: pos, size: size)
                        results.append(UIElement(axElement: tab, customFrame: frame))
                    }
                }
            }
        }

        // Try children (AXRadioGroup or other containers)
        if let children = parent.children {
            for child in children {
                let childRole = child.role ?? "Unknown"
                if childRole == "AXRadioButton" || childRole == "AXTab" {
                    if let pos = child.position, let size = child.size {
                        let posKey = "\(Int(pos.x)),\(Int(pos.y))"
                        if !scannedPositions.contains(posKey) && size.width > 10 && size.height > 10 {
                            scannedPositions.insert(posKey)
                            let frame = CGRect(origin: pos, size: size)
                            results.append(UIElement(axElement: child, customFrame: frame))
                        }
                    }
                }
            }
        }

        return results
    }
}

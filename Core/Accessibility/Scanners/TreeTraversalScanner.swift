import ApplicationServices
import Cocoa

/// Scans UI elements by recursively traversing the accessibility tree
/// Used as fallback when search predicates don't work (e.g., Electron apps)
final class TreeTraversalScanner: ElementScanner {
    private let maxElements: Int
    private let maxDepth: Int

    init(maxElements: Int = 1500, maxDepth: Int = 30) {
        self.maxElements = maxElements
        self.maxDepth = maxDepth
    }

    func scan(context: ScanContext) -> [UIElement] {
        guard let window = context.focusedWindow else { return [] }
        return traverseTree(from: window, depth: 0)
    }

    /// Traverse the accessibility tree recursively with limits
    private func traverseTree(from element: AXUIElement, depth: Int) -> [UIElement] {
        var results: [UIElement] = []

        // Limit depth to prevent infinite recursion
        guard depth < maxDepth else { return results }

        let uiElement = UIElement(axElement: element)

        // Add this element if it has a valid frame
        if uiElement.frame.width > 0 && uiElement.frame.height > 0 {
            results.append(uiElement)
        }

        // Stop if we have enough elements
        guard results.count < maxElements else { return results }

        // Traverse children
        if let children = element.children {
            // Limit to first 200 children to avoid extremely wide trees
            let limitedChildren = children.prefix(200)
            for child in limitedChildren {
                let remaining = maxElements - results.count
                guard remaining > 0 else { break }

                let childElements = traverseTree(from: child, depth: depth + 1)
                results.append(contentsOf: childElements)
            }
        }

        return results
    }
}

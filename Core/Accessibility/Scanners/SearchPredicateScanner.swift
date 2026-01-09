import ApplicationServices
import Cocoa

/// Scans UI elements using accessibility search predicates (fastest method)
final class SearchPredicateScanner: ElementScanner {
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

    func scan(context: ScanContext) -> [UIElement] {
        guard let window = context.focusedWindow else { return [] }
        return scanWindow(window)
    }

    /// Scan a single window for UI elements using search predicates
    private func scanWindow(_ window: AXUIElement) -> [UIElement] {
        var results: [UIElement] = []

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
}

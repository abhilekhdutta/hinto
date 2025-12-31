import Foundation

/// Generates unique labels for UI elements
final class LabelMaker {
    private let characters: [Character]

    init(characters: String = "ASDFGHJKLQWERTYUIOPZXCVBNM") {
        self.characters = Array(characters.uppercased())
    }

    /// Generate labels for a given count of elements
    /// For small counts, returns single characters (A, S, D, ...)
    /// For larger counts, returns multi-character labels (AA, AS, AD, ...)
    func generateLabels(count: Int) -> [String] {
        guard count > 0 else { return [] }

        var labels: [String] = []
        let charCount = characters.count

        if count <= charCount {
            // Single character labels
            for i in 0 ..< count {
                labels.append(String(characters[i]))
            }
        } else {
            // Calculate how many characters we need per label
            let charsNeeded = calculateCharsNeeded(for: count)
            labels = generateMultiCharLabels(count: count, length: charsNeeded)
        }

        return labels
    }

    /// Calculate minimum characters needed to represent the given count
    private func calculateCharsNeeded(for count: Int) -> Int {
        let charCount = characters.count
        var length = 1
        var capacity = charCount

        while capacity < count {
            length += 1
            capacity = Int(pow(Double(charCount), Double(length)))
        }

        return length
    }

    /// Generate multi-character labels
    private func generateMultiCharLabels(count: Int, length: Int) -> [String] {
        var labels: [String] = []
        let charCount = characters.count

        // Use a strategy that prioritizes easy-to-type combinations
        // Start with home row (ASDFGHJKL), then add other keys

        if length == 2 {
            // For 2-character labels, use first char as prefix
            outer: for first in characters {
                for second in characters {
                    labels.append("\(first)\(second)")
                    if labels.count >= count {
                        break outer
                    }
                }
            }
        } else {
            // For longer labels, generate sequentially
            for i in 0 ..< count {
                var label = ""
                var index = i

                for _ in 0 ..< length {
                    let charIndex = index % charCount
                    label = String(characters[charIndex]) + label
                    index /= charCount
                }

                labels.append(label)
            }
        }

        return labels
    }

    /// Assign labels to elements
    func assignLabels(to elements: inout [UIElement]) {
        let labels = generateLabels(count: elements.count)

        for (index, label) in labels.enumerated() {
            elements[index].label = label
        }
    }

    /// Filter elements by label prefix
    func filterByPrefix(_ prefix: String, elements: [UIElement]) -> [UIElement] {
        let uppercasedPrefix = prefix.uppercased()
        return elements.filter { $0.label.hasPrefix(uppercasedPrefix) }
    }

    /// Find exact match
    func findExactMatch(_ label: String, in elements: [UIElement]) -> UIElement? {
        let uppercasedLabel = label.uppercased()
        return elements.first { $0.label == uppercasedLabel }
    }
}

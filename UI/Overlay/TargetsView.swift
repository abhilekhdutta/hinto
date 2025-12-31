import Cocoa

/// View that displays target indicators for UI elements
final class TargetsView: NSView {
    private var targetLayers: [UUID: CALayer] = [:]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Show target indicators for elements
    func showTargets(for elements: [UIElement]) {
        clearTargets()

        guard let screenHeight = NSScreen.main?.frame.height else { return }

        for element in elements {
            let targetLayer = createTargetLayer(for: element, screenHeight: screenHeight)
            layer?.addSublayer(targetLayer)
            targetLayers[element.id] = targetLayer
        }
    }

    /// Clear all target indicators
    func clearTargets() {
        for (_, targetLayer) in targetLayers {
            targetLayer.removeFromSuperlayer()
        }
        targetLayers.removeAll()
    }

    /// Highlight a specific target
    func highlightTarget(_ element: UIElement) {
        guard let targetLayer = targetLayers[element.id] else { return }

        targetLayer.borderColor = NSColor.systemYellow.cgColor
        targetLayer.borderWidth = 3

        // Pulse animation
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.duration = 0.3
        animation.autoreverses = true
        animation.repeatCount = .infinity

        targetLayer.add(animation, forKey: "pulse")
    }

    // MARK: - Private

    private func createTargetLayer(for element: UIElement, screenHeight: CGFloat) -> CALayer {
        let targetLayer = CALayer()

        // Convert accessibility coordinates to screen coordinates
        let flippedY = screenHeight - element.frame.origin.y - element.frame.height

        targetLayer.frame = CGRect(
            x: element.frame.origin.x,
            y: flippedY,
            width: element.frame.width,
            height: element.frame.height
        )

        // Semi-transparent overlay
        targetLayer.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
        targetLayer.borderColor = NSColor.systemBlue.withAlphaComponent(0.5).cgColor
        targetLayer.borderWidth = 1
        targetLayer.cornerRadius = 2

        return targetLayer
    }
}

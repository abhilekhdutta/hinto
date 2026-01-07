import Cocoa

/// Window controller for the overlay that displays labels
final class OverlayWindowController: NSWindowController {
    private let overlayView: OverlayView

    init() {
        overlayView = OverlayView()

        // Overlay should be click-through so mouse events pass to apps below
        let panel = FloatingPanel(clickThrough: true)
        panel.contentView = overlayView

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Show labels for the given elements
    func showLabels(for elements: [UIElement]) {
        overlayView.showLabels(for: elements)
        (window as? FloatingPanel)?.showFullScreen()
    }

    /// Update visible labels based on filter
    func filterLabels(prefix: String) {
        overlayView.filterLabels(prefix: prefix)
    }

    /// Highlight a specific element
    func highlightElement(_ element: UIElement) {
        overlayView.highlightElement(element)
    }

    /// Hide the overlay
    func hide() {
        (window as? FloatingPanel)?.hide()
        overlayView.clearLabels()
    }
}

// MARK: - Overlay View

final class OverlayView: NSView {
    private var labelLayers: [UUID: LabelLayer] = [:]
    private var elements: [UIElement] = []

    private var theme: LabelTheme {
        let themeName = UserDefaults.standard.string(forKey: "label-theme") ?? "dark"
        switch themeName {
        case "light": return .light
        case "blue": return .blue
        case "custom":
            return .custom(
                background: Preferences.shared.customLabelBackground,
                text: Preferences.shared.customLabelText,
                border: Preferences.shared.customLabelBorder
            )
        default: return .dark
        }
    }

    private var labelSize: LabelSize {
        let sizeName = UserDefaults.standard.string(forKey: "label-size") ?? "medium"
        return LabelSize.fromString(sizeName)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Label Management

    func showLabels(for elements: [UIElement]) {
        clearLabels()
        self.elements = elements

        guard let screenHeight = NSScreen.main?.frame.height else { return }

        for element in elements {
            let labelLayer = createLabelLayer(for: element)
            labelLayer.positionRelativeTo(frame: element.frame, screenHeight: screenHeight)

            layer?.addSublayer(labelLayer)
            labelLayers[element.id] = labelLayer
        }
    }

    func filterLabels(prefix: String) {
        let uppercasedPrefix = prefix.uppercased()

        for element in elements {
            guard let labelLayer = labelLayers[element.id] else { continue }

            if prefix.isEmpty {
                // Show all
                labelLayer.opacity = 1.0
                labelLayer.isHidden = false
            } else if element.label.hasPrefix(uppercasedPrefix) {
                // Matching prefix - show
                labelLayer.opacity = 1.0
                labelLayer.isHidden = false

                // Highlight matched portion
                updateLabelHighlight(labelLayer, matchedLength: prefix.count)
            } else {
                // Not matching - hide
                labelLayer.opacity = 0.3
            }
        }
    }

    func highlightElement(_ element: UIElement) {
        guard let labelLayer = labelLayers[element.id] else { return }

        // Add highlight animation
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.2
        animation.duration = 0.1
        animation.autoreverses = true

        labelLayer.add(animation, forKey: "highlight")
    }

    func clearLabels() {
        for (_, labelLayer) in labelLayers {
            labelLayer.removeFromSuperlayer()
        }
        labelLayers.removeAll()
        elements.removeAll()
    }

    // MARK: - Private

    private func createLabelLayer(for element: UIElement) -> LabelLayer {
        let labelLayer = LabelLayer()
        labelLayer.label = element.label
        labelLayer.labelBackgroundColor = theme.backgroundColor
        labelLayer.labelTextColor = theme.textColor
        labelLayer.labelBorderColor = theme.borderColor
        // Apply size settings
        let size = labelSize
        labelLayer.labelFont = .monospacedSystemFont(ofSize: size.fontSize, weight: .bold)
        labelLayer.xPadding = size.xPadding
        labelLayer.yPadding = size.yPadding
        labelLayer.caretHeight = size.caretHeight
        labelLayer.caretWidth = size.caretWidth
        return labelLayer
    }

    private func updateLabelHighlight(_ labelLayer: LabelLayer, matchedLength: Int) {
        // Could implement partial highlighting here
        // For now, just scale up slightly when partially matched
        if matchedLength > 0 && matchedLength < labelLayer.label.count {
            labelLayer.transform = CATransform3DMakeScale(1.1, 1.1, 1.0)
        } else {
            labelLayer.transform = CATransform3DIdentity
        }
    }
}

import Cocoa
import QuartzCore

/// Direction of the caret (arrow) on the speech bubble
enum CaretDirection {
    case up // Caret points up (label below element)
    case down // Caret points down (label above element)
}

/// A CALayer that draws a label for a UI element with speech bubble style
final class LabelLayer: CALayer {
    var label: String = "" {
        didSet { updateLayout() }
    }

    /// Direction of the caret - set by positionRelativeTo
    private(set) var caretDirection: CaretDirection = .up {
        didSet { if oldValue != caretDirection { updateLayout() } }
    }

    var labelFont: NSFont = .monospacedSystemFont(ofSize: 10, weight: .bold) {
        didSet { updateLayout() }
    }

    var labelTextColor: NSColor = .white {
        didSet { textLayer.foregroundColor = labelTextColor.cgColor }
    }

    var labelBackgroundColor: NSColor = .systemBlue {
        didSet { shapeLayer.fillColor = labelBackgroundColor.cgColor }
    }

    var labelBorderColor: NSColor = .white {
        didSet { shapeLayer.strokeColor = labelBorderColor.cgColor }
    }

    var xPadding: CGFloat = 4
    var yPadding: CGFloat = 2
    var caretHeight: CGFloat = 5
    var caretWidth: CGFloat = 7

    private let shapeLayer = CAShapeLayer()
    private let textLayer = CATextLayer()

    override init() {
        super.init()
        setupLayer()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let labelLayer = layer as? LabelLayer {
            label = labelLayer.label
            labelFont = labelLayer.labelFont
            labelTextColor = labelLayer.labelTextColor
            labelBackgroundColor = labelLayer.labelBackgroundColor
        }
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        // Set scale on self for Retina display
        contentsScale = scale

        // Shape layer for speech bubble
        shapeLayer.fillColor = labelBackgroundColor.cgColor
        shapeLayer.strokeColor = labelBorderColor.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.contentsScale = scale
        addSublayer(shapeLayer)

        // Shadow on shape
        shapeLayer.shadowColor = NSColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: -1)
        shapeLayer.shadowRadius = 2
        shapeLayer.shadowOpacity = 0.4

        // Text layer
        textLayer.contentsScale = scale
        textLayer.alignmentMode = .center
        textLayer.truncationMode = .none
        addSublayer(textLayer)

        updateLayout()
    }

    private func updateLayout() {
        textLayer.font = labelFont
        textLayer.fontSize = labelFont.pointSize
        textLayer.foregroundColor = labelTextColor.cgColor
        textLayer.string = label

        // Calculate size
        let textSize = calculateTextSize()
        let bubbleWidth = textSize.width + (xPadding * 2)
        let bubbleHeight = textSize.height + (yPadding * 2)
        let totalHeight = bubbleHeight + caretHeight

        bounds = CGRect(x: 0, y: 0, width: bubbleWidth, height: totalHeight)

        // Create speech bubble path with caret in the appropriate direction
        let path = createBubblePath(
            width: bubbleWidth,
            height: totalHeight,
            bubbleHeight: bubbleHeight,
            direction: caretDirection
        )
        shapeLayer.path = path
        shapeLayer.frame = bounds

        // Position text in the bubble
        // When caret points up: text is at bottom (y = yPadding)
        // When caret points down: text is above the caret (y = yPadding + caretHeight)
        let textY = caretDirection == .up ? yPadding : yPadding + caretHeight
        textLayer.frame = CGRect(
            x: xPadding,
            y: textY,
            width: textSize.width,
            height: textSize.height
        )
    }

    private func createBubblePath(
        width: CGFloat,
        height: CGFloat,
        bubbleHeight: CGFloat,
        direction: CaretDirection
    ) -> CGPath {
        let path = CGMutablePath()
        let cornerRadius: CGFloat = 3
        let caretX = width / 2

        switch direction {
        case .up:
            // Caret at top, pointing up (label below element)
            // Bubble body is at bottom (y: 0 to bubbleHeight)
            // Caret tip is at top (y: height)

            path.move(to: CGPoint(x: 0, y: cornerRadius))

            // Left edge up
            path.addLine(to: CGPoint(x: 0, y: bubbleHeight - cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: 0, y: bubbleHeight),
                tangent2End: CGPoint(x: cornerRadius, y: bubbleHeight),
                radius: cornerRadius
            )

            // Top edge to caret
            path.addLine(to: CGPoint(x: caretX - caretWidth / 2, y: bubbleHeight))
            path.addLine(to: CGPoint(x: caretX, y: height)) // Caret tip
            path.addLine(to: CGPoint(x: caretX + caretWidth / 2, y: bubbleHeight))

            // Top edge to top-right corner
            path.addLine(to: CGPoint(x: width - cornerRadius, y: bubbleHeight))
            path.addArc(
                tangent1End: CGPoint(x: width, y: bubbleHeight),
                tangent2End: CGPoint(x: width, y: bubbleHeight - cornerRadius),
                radius: cornerRadius
            )

            // Right edge down
            path.addLine(to: CGPoint(x: width, y: cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: width, y: 0),
                tangent2End: CGPoint(x: width - cornerRadius, y: 0),
                radius: cornerRadius
            )

            // Bottom edge
            path.addLine(to: CGPoint(x: cornerRadius, y: 0))
            path.addArc(
                tangent1End: CGPoint(x: 0, y: 0),
                tangent2End: CGPoint(x: 0, y: cornerRadius),
                radius: cornerRadius
            )

        case .down:
            // Caret at bottom, pointing down (label above element)
            // Caret tip is at bottom (y: 0)
            // Bubble body is at top (y: caretHeight to height)

            path.move(to: CGPoint(x: 0, y: caretHeight + cornerRadius))

            // Left edge up
            path.addLine(to: CGPoint(x: 0, y: height - cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: 0, y: height),
                tangent2End: CGPoint(x: cornerRadius, y: height),
                radius: cornerRadius
            )

            // Top edge
            path.addLine(to: CGPoint(x: width - cornerRadius, y: height))
            path.addArc(
                tangent1End: CGPoint(x: width, y: height),
                tangent2End: CGPoint(x: width, y: height - cornerRadius),
                radius: cornerRadius
            )

            // Right edge down
            path.addLine(to: CGPoint(x: width, y: caretHeight + cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: width, y: caretHeight),
                tangent2End: CGPoint(x: width - cornerRadius, y: caretHeight),
                radius: cornerRadius
            )

            // Bottom edge to caret
            path.addLine(to: CGPoint(x: caretX + caretWidth / 2, y: caretHeight))
            path.addLine(to: CGPoint(x: caretX, y: 0)) // Caret tip pointing down
            path.addLine(to: CGPoint(x: caretX - caretWidth / 2, y: caretHeight))

            // Bottom edge to bottom-left corner
            path.addLine(to: CGPoint(x: cornerRadius, y: caretHeight))
            path.addArc(
                tangent1End: CGPoint(x: 0, y: caretHeight),
                tangent2End: CGPoint(x: 0, y: caretHeight + cornerRadius),
                radius: cornerRadius
            )
        }

        path.closeSubpath()
        return path
    }

    private func calculateTextSize() -> CGSize {
        let attributedString = NSAttributedString(
            string: label,
            attributes: [.font: labelFont]
        )
        let size = attributedString.size()
        return CGSize(
            width: ceil(size.width),
            height: ceil(size.height)
        )
    }

    /// Position the label relative to a UI element frame
    /// For elements near the bottom of screen: label above with caret pointing down
    /// For other elements: label below with caret pointing up
    func positionRelativeTo(frame: CGRect, screenHeight: CGFloat) {
        // Convert from accessibility coordinates (top-left origin, Y down)
        // to layer coordinates (bottom-left origin, Y up)

        let elementTop = screenHeight - frame.origin.y
        let elementBottom = screenHeight - (frame.origin.y + frame.height)

        // Label center X = element center X
        let x = frame.origin.x + (frame.width / 2)

        // Determine if element is in bottom portion of screen
        // Use accessibility coordinates (Y down from top)
        let bottomThreshold = screenHeight * 0.75
        let isNearBottom = frame.origin.y > bottomThreshold

        var y: CGFloat
        if isNearBottom {
            // Position label above element, caret points down
            caretDirection = .down
            // Caret tip (at y=0 of bounds) should touch element top
            // position.y - bounds.height/2 = elementTop
            y = elementTop + bounds.height / 2
        } else {
            // Position label below element, caret points up
            caretDirection = .up
            // Caret tip (at y=bounds.height of bounds) should touch element bottom
            // position.y + bounds.height/2 = elementBottom
            y = elementBottom - bounds.height / 2
        }

        // Ensure label stays within screen bounds
        let minY = bounds.height / 2 + 10
        let maxY = screenHeight - bounds.height / 2 - 10
        y = max(minY, min(y, maxY))

        position = CGPoint(x: x, y: y)
    }
}

// MARK: - Label Size

struct LabelSize {
    var fontSize: CGFloat
    var xPadding: CGFloat
    var yPadding: CGFloat
    var caretHeight: CGFloat
    var caretWidth: CGFloat

    static let small = LabelSize(fontSize: 8, xPadding: 2, yPadding: 1, caretHeight: 3, caretWidth: 5)
    static let medium = LabelSize(fontSize: 10, xPadding: 4, yPadding: 2, caretHeight: 5, caretWidth: 7)
    static let large = LabelSize(fontSize: 12, xPadding: 5, yPadding: 3, caretHeight: 6, caretWidth: 8)

    static func fromString(_ name: String) -> LabelSize {
        switch name {
        case "small": return .small
        case "large": return .large
        default: return .medium
        }
    }
}

// MARK: - Label Theme

struct LabelTheme {
    var backgroundColor: NSColor
    var textColor: NSColor
    var borderColor: NSColor

    static let dark = LabelTheme(
        backgroundColor: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.95),
        textColor: .white,
        borderColor: NSColor(white: 0.4, alpha: 1.0)
    )

    static let light = LabelTheme(
        backgroundColor: NSColor(white: 0.95, alpha: 0.95),
        textColor: .black,
        borderColor: NSColor(white: 0.7, alpha: 1.0)
    )

    static let blue = LabelTheme(
        backgroundColor: .systemBlue,
        textColor: .white,
        borderColor: .white
    )

    /// Create a custom theme with user-specified colors
    static func custom(background: NSColor, text: NSColor, border: NSColor) -> LabelTheme {
        LabelTheme(backgroundColor: background, textColor: text, borderColor: border)
    }
}

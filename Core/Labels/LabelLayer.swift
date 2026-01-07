import Cocoa
import QuartzCore

/// A CALayer that draws a label for a UI element with speech bubble style
final class LabelLayer: CALayer {
    var label: String = "" {
        didSet { updateLayout() }
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
        // Shape layer for speech bubble
        shapeLayer.fillColor = labelBackgroundColor.cgColor
        shapeLayer.strokeColor = labelBorderColor.cgColor
        shapeLayer.lineWidth = 1
        addSublayer(shapeLayer)

        // Shadow on shape
        shapeLayer.shadowColor = NSColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: -1)
        shapeLayer.shadowRadius = 2
        shapeLayer.shadowOpacity = 0.4

        // Text layer
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
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

        // Create speech bubble path with caret pointing up
        let path = createBubblePath(width: bubbleWidth, height: totalHeight, bubbleHeight: bubbleHeight)
        shapeLayer.path = path
        shapeLayer.frame = bounds

        // Position text in the bubble (below the caret)
        textLayer.frame = CGRect(
            x: xPadding,
            y: yPadding,
            width: textSize.width,
            height: textSize.height
        )
    }

    private func createBubblePath(width: CGFloat, height: CGFloat, bubbleHeight: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let cornerRadius: CGFloat = 3
        let caretX = width / 2

        // Start from bottom-left, go clockwise
        // Bottom-left corner
        path.move(to: CGPoint(x: 0, y: cornerRadius))

        // Left edge up to top-left corner
        path.addLine(to: CGPoint(x: 0, y: bubbleHeight - cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: 0, y: bubbleHeight),
            tangent2End: CGPoint(x: cornerRadius, y: bubbleHeight),
            radius: cornerRadius
        )

        // Top edge to caret left
        path.addLine(to: CGPoint(x: caretX - caretWidth / 2, y: bubbleHeight))

        // Caret pointing up
        path.addLine(to: CGPoint(x: caretX, y: height))
        path.addLine(to: CGPoint(x: caretX + caretWidth / 2, y: bubbleHeight))

        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: width - cornerRadius, y: bubbleHeight))
        path.addArc(
            tangent1End: CGPoint(x: width, y: bubbleHeight),
            tangent2End: CGPoint(x: width, y: bubbleHeight - cornerRadius),
            radius: cornerRadius
        )

        // Right edge down to bottom-right corner
        path.addLine(to: CGPoint(x: width, y: cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: width, y: 0),
            tangent2End: CGPoint(x: width - cornerRadius, y: 0),
            radius: cornerRadius
        )

        // Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: cornerRadius, y: 0))
        path.addArc(
            tangent1End: CGPoint(x: 0, y: 0),
            tangent2End: CGPoint(x: 0, y: cornerRadius),
            radius: cornerRadius
        )

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

    /// Position the label below a UI element frame with caret pointing up
    func positionRelativeTo(frame: CGRect, screenHeight: CGFloat) {
        // Convert from accessibility coordinates (top-left origin, Y down)
        // to layer coordinates (bottom-left origin, Y up)

        // Element bottom edge in layer coordinates
        let elementBottom = screenHeight - (frame.origin.y + frame.height)

        // Label center X = element center X
        let x = frame.origin.x + (frame.width / 2)

        // Label top (caret tip) should touch element bottom
        // position.y is at center of bounds, caret tip is at bounds.height from bottom
        // So: position.y + bounds.height/2 = elementBottom
        // Therefore: position.y = elementBottom - bounds.height/2
        let y = elementBottom - bounds.height / 2

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

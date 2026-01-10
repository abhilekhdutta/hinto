import SwiftUI

/// View displaying changelog for "What's New" popup
struct WhatsNewView: View {
    let entry: ChangelogEntry
    let isPostUpdate: Bool
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.top, Design.Spacing.xxxl)
                .padding(.bottom, Design.Spacing.xl)

            // Content
            ScrollView {
                Text(.init(entry.content))
                    .font(Design.Font.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Design.Spacing.xxxl)
                    .padding(.vertical, Design.Spacing.xl)
            }
            .frame(maxHeight: .infinity)

            // Footer
            footer
                .padding(.top, Design.Spacing.lg)
                .padding(.bottom, Design.Spacing.huge)
        }
        .frame(width: 480, height: 500)
        .background {
            ZStack {
                // Base material (same as Settings)
                RoundedRectangle(cornerRadius: Design.CornerRadius.xl)
                    .fill(.thickMaterial)

                // Subtle gradient overlay
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.15)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Design.CornerRadius.xl))
    }

    private var gradientColors: [Color] {
        colorScheme == .dark
            ? [Design.Colors.accent.opacity(0.3), Design.Colors.accent.opacity(0.15)]
            : [Design.Colors.accent.opacity(0.2), Design.Colors.accent.opacity(0.1)]
    }

    private var header: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: Design.IconSize.lg, height: Design.IconSize.lg)

            Text("What's New")
                .font(Design.Font.title)

            Text("Version \(entry.version)")
                .font(Design.Font.button)
                .foregroundColor(.secondary)
        }
    }

    private var footer: some View {
        Button(action: {
            if isPostUpdate {
                // Mark as seen only for post-update popup
                Preferences.shared.lastSeenVersion = Preferences.shared.currentVersion
            }
            onDismiss()
        }) {
            Text(isPostUpdate ? "Continue" : "Close")
        }
        .buttonStyle(.hintoCard)
    }
}

// MARK: - Window Controller

final class WhatsNewWindowController: NSWindowController {
    private var externalOnDismiss: (() -> Void)?

    convenience init(entry: ChangelogEntry, onDismiss: (() -> Void)? = nil) {
        let whatsNewView = WhatsNewView(entry: entry, isPostUpdate: true) {
            // Will be set after window is created
        }

        let hostingController = NSHostingController(rootView: whatsNewView)
        hostingController.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: hostingController)
        window.title = "What's New"
        window.styleMask = [.titled, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.setContentSize(NSSize(width: 480, height: 500))
        window.center()

        self.init(window: window)
        externalOnDismiss = onDismiss

        // Update the view with proper dismiss handler (isPostUpdate: true for window controller)
        let updatedView = WhatsNewView(entry: entry, isPostUpdate: true) { [weak self] in
            self?.dismissWindow()
        }
        hostingController.rootView = updatedView
    }

    private func dismissWindow() {
        close()
        externalOnDismiss?()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview("Post Update") {
    WhatsNewView(
        entry: ChangelogEntry(
            version: "0.1.0",
            date: "2026-01-01",
            content: """
            **Added**

            - Initial release
            - Keyboard-driven UI navigation with hint labels
            - Global hotkey activation (Cmd+Shift+Space)

            **Fixed**

            - Some bug fixes
            """
        ),
        isPostUpdate: true,
        onDismiss: {}
    )
}

#Preview("Manual") {
    WhatsNewView(
        entry: ChangelogEntry(
            version: "0.1.0",
            date: "2026-01-01",
            content: """
            **Added**

            - Initial release
            """
        ),
        isPostUpdate: false,
        onDismiss: {}
    )
}

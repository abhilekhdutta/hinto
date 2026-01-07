import ServiceManagement
import SwiftUI

// MARK: - Color Theme

struct SettingsColors {
    let background: Material
    let cardBackground: Color
    let text: Color
    let secondaryText: Color

    static func forScheme(_ scheme: ColorScheme) -> SettingsColors {
        if scheme == .dark {
            return SettingsColors(
                background: .thickMaterial,
                cardBackground: Color(red: 0x4A / 255.0, green: 0x49 / 255.0, blue: 0x49 / 255.0).opacity(0.5),
                text: .white,
                secondaryText: Color(white: 0.5)
            )
        } else {
            return SettingsColors(
                background: .thickMaterial,
                cardBackground: Color(red: 0xD0 / 255.0, green: 0xCE / 255.0, blue: 0xCD / 255.0).opacity(0.5),
                text: .black,
                secondaryText: Color(white: 0.4)
            )
        }
    }
}

// MARK: - Main Settings View

struct SettingsView: View {
    @State private var selectedTab = 0
    @AppStorage("app-appearance") private var appAppearance = "system"
    @Environment(\.colorScheme) private var systemColorScheme

    private var effectiveColorScheme: ColorScheme? {
        switch appAppearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var currentScheme: ColorScheme {
        effectiveColorScheme ?? systemColorScheme
    }

    var body: some View {
        let colors = SettingsColors.forScheme(currentScheme)

        VStack(spacing: 0) {
            // Custom toolbar
            SettingsToolbar(selectedTab: $selectedTab, colors: colors)
                .padding(.top, 8)

            // Content
            TabContent(selectedTab: selectedTab, colors: colors)
        }
        .frame(width: 560, height: 420)
        .background(colors.background)
        .preferredColorScheme(effectiveColorScheme)
    }
}

// MARK: - Settings Toolbar

struct SettingsToolbar: View {
    @Binding var selectedTab: Int
    let colors: SettingsColors

    private let tabs: [(icon: String, title: String)] = [
        ("gear", "General"),
        ("keyboard", "Shortcuts"),
        ("paintbrush", "Appearance"),
        ("info.circle", "About"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< tabs.count, id: \.self) { index in
                ToolbarTab(
                    icon: tabs[index].icon,
                    title: tabs[index].title,
                    isSelected: selectedTab == index,
                    colors: colors
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ToolbarTab: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let colors: SettingsColors

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 28, height: 28)

            Text(title)
                .font(.system(size: 11))
        }
        .foregroundColor(isSelected ? .white : colors.secondaryText)
        .frame(width: 80, height: 56)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.6))
                        )
                } else {
                    Color.clear
                }
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: Int
    let colors: SettingsColors

    var body: some View {
        Group {
            switch selectedTab {
            case 0: GeneralSettingsView(colors: colors)
            case 1: ShortcutsSettingsView(colors: colors)
            case 2: AppearanceSettingsView(colors: colors)
            case 3: AboutView(colors: colors)
            default: EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let label: String
    let colors: SettingsColors
    let content: Content

    init(_ label: String, colors: SettingsColors, @ViewBuilder content: () -> Content) {
        self.label = label
        self.colors = colors
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .foregroundColor(colors.secondaryText)
                .frame(width: 140, alignment: .trailing)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    let colors: SettingsColors
    @AppStorage("label-characters") private var labelCharacters = "ASDFGHJKLQWERTYUIOPZXCVBNM"
    @AppStorage("is-auto-click-enabled") private var autoClickEnabled = false
    @State private var accessibilityEnabled = AXEnablerService.shared.isAccessibilityEnabled
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            SettingsRow("Launch at Login", colors: colors) {
                Toggle("Start Hinto when you log in", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            SettingsRow("Auto Click", colors: colors) {
                Toggle("Click when label matches exactly", isOn: $autoClickEnabled)
                    .toggleStyle(.checkbox)
            }

            SettingsRow("Label Characters", colors: colors) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labelCharacters)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.cardBackground)
                        .cornerRadius(6)
                    Text("Characters used for hint labels")
                        .font(.caption)
                        .foregroundColor(colors.secondaryText)
                }
            }

            SettingsRow("Accessibility", colors: colors) {
                HStack(spacing: 12) {
                    if accessibilityEnabled {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Enabled")
                                .foregroundColor(colors.text)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Not Enabled")
                                .foregroundColor(colors.text)
                        }

                        Button("Grant Access") {
                            AXEnablerService.shared.promptForAccessibility()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                accessibilityEnabled = AXEnablerService.shared.isAccessibilityEnabled
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    let colors: SettingsColors

    var body: some View {
        VStack(spacing: 0) {
            SettingsRow("Activate Hinto", colors: colors) {
                HotkeyBadge(keys: ["Cmd", "Shift", "Space"], colors: colors)
            }

            SettingsRow("Left Click", colors: colors) {
                Text("Type the label")
                    .foregroundColor(colors.text)
            }

            SettingsRow("Right Click", colors: colors) {
                HStack(spacing: 4) {
                    KeyBadge("Shift", colors: colors)
                    Text("+")
                        .foregroundColor(colors.secondaryText)
                    Text("last character")
                        .foregroundColor(colors.text)
                }
            }

            SettingsRow("Switch Mode", colors: colors) {
                HStack(spacing: 8) {
                    KeyBadge("Tab", colors: colors)
                    Text("Toggle click/scroll mode")
                        .foregroundColor(colors.secondaryText)
                }
            }

            SettingsRow("Scroll Mode", colors: colors) {
                ScrollKeyGuide(colors: colors)
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

struct HotkeyBadge: View {
    let keys: [String]
    let colors: SettingsColors

    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(keySymbol(key))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colors.text)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(colors.cardBackground)
        .cornerRadius(6)
    }

    func keySymbol(_ key: String) -> String {
        switch key {
        case "Cmd": return "\u{21E7}\u{2318} Space"
        case "Shift": return ""
        case "Space": return ""
        default: return key
        }
    }
}

struct KeyBadge: View {
    let key: String
    let colors: SettingsColors

    init(_ key: String, colors: SettingsColors) {
        self.key = key
        self.colors = colors
    }

    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(colors.text)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(colors.cardBackground)
            .cornerRadius(4)
    }
}

struct ScrollKeyGuide: View {
    let colors: SettingsColors

    var body: some View {
        HStack(spacing: 20) {
            KeyGuideItem(key: "H", arrow: "\u{2190}", colors: colors)
            KeyGuideItem(key: "J", arrow: "\u{2193}", colors: colors)
            KeyGuideItem(key: "K", arrow: "\u{2191}", colors: colors)
            KeyGuideItem(key: "L", arrow: "\u{2192}", colors: colors)
            KeyGuideItem(key: "D", arrow: "\u{21A1}", colors: colors)
            KeyGuideItem(key: "U", arrow: "\u{219F}", colors: colors)
        }
    }
}

struct KeyGuideItem: View {
    let key: String
    let arrow: String
    let colors: SettingsColors

    var body: some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(colors.text)
            Text(arrow)
                .font(.system(size: 10))
                .foregroundColor(colors.secondaryText)
        }
        .frame(width: 32, height: 36)
        .background(colors.cardBackground)
        .cornerRadius(6)
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    let colors: SettingsColors
    @AppStorage("app-appearance") private var appAppearance = "system"
    @AppStorage("label-theme") private var labelTheme = "dark"
    @AppStorage("label-size") private var labelSize = "medium"

    // Custom color states
    @State private var customBackground: Color = .init(Preferences.shared.customLabelBackground)
    @State private var customText: Color = .init(Preferences.shared.customLabelText)
    @State private var customBorder: Color = .init(Preferences.shared.customLabelBorder)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SettingsRow("Appearance", colors: colors) {
                    HStack(spacing: 12) {
                        AppearanceOption(
                            icon: "sun.max",
                            label: "Light",
                            isSelected: appAppearance == "light",
                            colors: colors
                        ) {
                            appAppearance = "light"
                        }

                        AppearanceOption(
                            icon: "moon",
                            label: "Dark",
                            isSelected: appAppearance == "dark",
                            colors: colors
                        ) {
                            appAppearance = "dark"
                        }

                        AppearanceOption(
                            icon: "circle.lefthalf.filled",
                            label: "System",
                            isSelected: appAppearance == "system",
                            colors: colors
                        ) {
                            appAppearance = "system"
                        }
                    }
                }

                SettingsRow("Label Theme", colors: colors) {
                    HStack(spacing: 12) {
                        ThemeOption(
                            icon: "sun.max",
                            label: "Light",
                            isSelected: labelTheme == "light",
                            colors: colors
                        ) {
                            labelTheme = "light"
                        }

                        ThemeOption(
                            icon: "moon",
                            label: "Dark",
                            isSelected: labelTheme == "dark",
                            colors: colors
                        ) {
                            labelTheme = "dark"
                        }

                        ThemeOption(
                            icon: "drop.fill",
                            label: "Blue",
                            isSelected: labelTheme == "blue",
                            colors: colors
                        ) {
                            labelTheme = "blue"
                        }

                        ThemeOption(
                            icon: "paintpalette",
                            label: "Custom",
                            isSelected: labelTheme == "custom",
                            colors: colors
                        ) {
                            labelTheme = "custom"
                        }
                    }
                }

                if labelTheme == "custom" {
                    SettingsRow("Background", colors: colors) {
                        ColorPicker("", selection: $customBackground, supportsOpacity: true)
                            .labelsHidden()
                            .onChange(of: customBackground) { newValue in
                                Preferences.shared.customLabelBackground = NSColor(newValue)
                            }
                    }

                    SettingsRow("Text", colors: colors) {
                        ColorPicker("", selection: $customText, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: customText) { newValue in
                                Preferences.shared.customLabelText = NSColor(newValue)
                            }
                    }

                    SettingsRow("Border", colors: colors) {
                        ColorPicker("", selection: $customBorder, supportsOpacity: true)
                            .labelsHidden()
                            .onChange(of: customBorder) { newValue in
                                Preferences.shared.customLabelBorder = NSColor(newValue)
                            }
                    }
                }

                SettingsRow("Label Size", colors: colors) {
                    HStack(spacing: 12) {
                        SizeOption(
                            label: "S",
                            isSelected: labelSize == "small",
                            colors: colors
                        ) {
                            labelSize = "small"
                        }

                        SizeOption(
                            label: "M",
                            isSelected: labelSize == "medium",
                            colors: colors
                        ) {
                            labelSize = "medium"
                        }

                        SizeOption(
                            label: "L",
                            isSelected: labelSize == "large",
                            colors: colors
                        ) {
                            labelSize = "large"
                        }
                    }
                }

                SettingsRow("Preview", colors: colors) {
                    LabelPreview(
                        theme: labelTheme,
                        size: labelSize,
                        colors: colors,
                        customBackground: customBackground,
                        customText: customText,
                        customBorder: customBorder
                    )
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }
}

struct AppearanceOption: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let colors: SettingsColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : colors.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.regularMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.6))
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.cardBackground)
                            }
                        }
                    )

                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? colors.text : colors.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ThemeOption: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let colors: SettingsColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : colors.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.regularMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.6))
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.cardBackground)
                            }
                        }
                    )

                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? colors.text : colors.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SizeOption: View {
    let label: String
    let isSelected: Bool
    let colors: SettingsColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : colors.secondaryText)
                .frame(width: 36, height: 36)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.6))
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors.cardBackground)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

struct LabelPreview: View {
    let theme: String
    let size: String
    let colors: SettingsColors
    var customBackground: Color = .init(white: 0.2)
    var customText: Color = .white
    var customBorder: Color = .init(white: 0.4)

    var backgroundColor: Color {
        switch theme {
        case "light": return Color(white: 0.95)
        case "blue": return Color.blue
        case "custom": return customBackground
        default: return Color(white: 0.2)
        }
    }

    var textColor: Color {
        switch theme {
        case "light": return .black
        case "custom": return customText
        default: return .white
        }
    }

    var borderColor: Color {
        switch theme {
        case "light": return Color(white: 0.7)
        case "blue": return .white
        case "custom": return customBorder
        default: return Color(white: 0.4)
        }
    }

    var fontSize: CGFloat {
        switch size {
        case "small": return 10
        case "large": return 16
        default: return 13
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(["A", "S", "D", "F"], id: \.self) { label in
                Text(label)
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
                    .padding(.horizontal, size == "small" ? 4 : (size == "large" ? 10 : 8))
                    .padding(.vertical, size == "small" ? 2 : (size == "large" ? 6 : 4))
                    .background(backgroundColor)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor, lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.cardBackground)
        )
    }
}

// MARK: - About View

struct AboutView: View {
    let colors: SettingsColors

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image("AboutIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            VStack(spacing: 4) {
                Text("Hinto")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colors.text)

                Text("Version \(appVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(colors.secondaryText)
            }

            Text("Navigate your Mac without a mouse\nusing keyboard-driven labels.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(colors.secondaryText)
                .lineSpacing(4)

            Spacer()

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/yhao3/hinto")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "star")
                        Text("Star on GitHub")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.cardBackground)
                    .cornerRadius(6)
                }

                Link(destination: URL(string: "https://ko-fi.com/yhao3")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                        Text("Donate")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.cardBackground)
                    .cornerRadius(6)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}

import Foundation

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let labelCharacters = "label-characters"
        static let labelSize = "label-size"
        static let activationShortcut = "activation-shortcut"
        static let showMenuBarIcon = "show-menubar-icon"
        static let autoClickEnabled = "is-auto-click-enabled"
        static let hideLabelsWhenNothingSearched = "hide-labels-when-nothing-is-searched"
    }

    // MARK: - Properties

    var labelCharacters: String {
        get { defaults.string(forKey: Keys.labelCharacters) ?? "ASDFGHJKLQWERTYUIOPZXCVBNM" }
        set { defaults.set(newValue, forKey: Keys.labelCharacters) }
    }

    /// Label size: "small", "medium", "large"
    var labelSize: String {
        get { defaults.string(forKey: Keys.labelSize) ?? "medium" }
        set { defaults.set(newValue, forKey: Keys.labelSize) }
    }

    var showMenuBarIcon: Bool {
        get { defaults.bool(forKey: Keys.showMenuBarIcon) }
        set { defaults.set(newValue, forKey: Keys.showMenuBarIcon) }
    }

    var autoClickEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoClickEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoClickEnabled) }
    }

    var hideLabelsWhenNothingSearched: Bool {
        get { defaults.bool(forKey: Keys.hideLabelsWhenNothingSearched) }
        set { defaults.set(newValue, forKey: Keys.hideLabelsWhenNothingSearched) }
    }
}

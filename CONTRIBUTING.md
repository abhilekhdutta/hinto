# Contributing

## Building the Project

### First-Time Setup

Run the setup script to create a local self-signed code signing certificate:

```bash
make setup
```

This creates a "Local Self-Signed" certificate in your Keychain, which prevents having to re-grant Accessibility permissions on every rebuild.

### Build and Run

```bash
make run    # Build and run the app
make build  # Build only
make test   # Run unit tests
make clean  # Remove build artifacts
make log    # Watch debug log
```

### Accessibility Permission

After the first launch, grant Accessibility permission:

1. Open **System Settings > Privacy & Security > Accessibility**
2. Enable **Hinto**
3. Restart the app with `make run`

## Project Structure

| Path | Description |
|------|-------------|
| `App/` | Application entry point and lifecycle |
| `Config/` | Xcode build configuration (xcconfig files) |
| `Core/` | Core functionality (accessibility, labels, events) |
| `Mode/` | Mode controllers (click mode, scroll mode) |
| `Scripts/` | Build and setup scripts |
| `UI/` | User interface components |
| `Resources/` | Assets, Info.plist, entitlements |
| `Tests/` | Unit tests |

## Code Signing

The project uses xcconfig files for build settings:

| File | Purpose |
|------|---------|
| `Config/base.xcconfig` | Shared settings |
| `Config/debug.xcconfig` | Debug builds (Local Self-Signed) |
| `Config/release.xcconfig` | Release builds |

For distribution, update `Config/release.xcconfig` with your Developer ID:

```
CODE_SIGN_IDENTITY = Developer ID Application: Your Name (TEAM_ID)
```

## Logging

Logs use Apple's unified logging (`os.Logger`). To enable file logging:

```bash
defaults write dev.yhao3.hinto debug-file-logging -bool true
```

Logs are written to `/tmp/hinto.log`. View with:

```bash
make log
# or
tail -f /tmp/hinto.log
```

## Code Style

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for consistent code formatting.

### Install SwiftFormat

```bash
brew install swiftformat
```

### Format Code

```bash
swiftformat .
```

### Check Only (CI)

```bash
swiftformat --lint .
```

Configuration is in `.swiftformat`.

## Testing

```bash
make test
```

Tests are run via Swift Package Manager. Only pure functions are tested.

## Architecture

### Key Components

- **UITreeBuilder**: Scans accessibility hierarchy for clickable elements
- **UITree**: Filters and deduplicates elements
- **LabelMaker**: Generates unique labels for elements
- **ModeController**: Manages click mode lifecycle
- **EventTapManager**: Global keyboard event monitoring

### Accessibility APIs

The app uses macOS Accessibility APIs:

- `AXUIElement` for querying UI elements
- `AXObserver` for UI change notifications
- `CGEventTap` for global hotkey detection

Search predicates used:
- `AXButtonSearchKey`, `AXLinkSearchKey`, `AXControlSearchKey`
- `AXTextFieldSearchKey`, `AXMenuItemSearchKey`
- `AXKeyboardFocusableSearchKey`

## License

MIT License

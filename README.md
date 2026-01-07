<p align="center">
  <img src="logo.png" width="128" height="128" alt="Hinto Logo">
</p>

<h1 align="center">Hinto</h1>

<p align="center">
  <strong>Keyboard-driven UI navigation for macOS</strong>
</p>

<p align="center">
  Navigate any macOS app without a mouse using accessibility labels.
</p>

<p align="center">
  <a href="https://github.com/yhao3/hinto/releases"><img src="https://img.shields.io/github/v/release/yhao3/hinto?label=Download" alt="Download"></a>
  <a href="https://github.com/yhao3/hinto/actions"><img src="https://img.shields.io/github/actions/workflow/status/yhao3/hinto/ci.yml?branch=main&label=CI" alt="CI"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/yhao3/hinto" alt="License"></a>
</p>

<p align="center">
  <a href="https://ko-fi.com/yhao3"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Support on Ko-fi"></a>
</p>

---

## Features

- **Click Mode**: Press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd> to show labels on clickable elements
- **Scroll Mode**: Press <kbd>Tab</kbd> to switch to scroll mode with vim-like keys (<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd>)
- **Configurable Labels**: Choose label size (S/M/L) and theme (Dark/Light/Blue)
- **Auto-click**: Automatically click when an exact label match is typed

## Installation

### Build from Source

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup.

```bash
cd Hinto
make setup  # First time only: create code signing certificate
make run
```

### Requirements

- macOS 13.0+
- Xcode 15.0+
- **Accessibility Permission** (required for global hotkeys)

## Usage

1. Press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd> to activate
2. Type the label of the element you want to click
3. Press <kbd>Enter</kbd> to confirm, or wait for auto-click
4. Press <kbd>Shift</kbd>+<kbd>Enter</kbd> for right-click
5. Press <kbd>Tab</kbd> to switch to scroll mode
6. Press <kbd>Escape</kbd> to cancel

### Scroll Mode Keys

| Key | Action |
|-----|--------|
| <kbd>J</kbd> | Scroll down |
| <kbd>K</kbd> | Scroll up |
| <kbd>H</kbd> | Scroll left |
| <kbd>L</kbd> | Scroll right |
| <kbd>D</kbd> | Half page down |
| <kbd>U</kbd> | Half page up |
| <kbd>Shift</kbd>+<kbd>J</kbd>/<kbd>K</kbd>/<kbd>H</kbd>/<kbd>L</kbd> | Fast scroll |

## Configuration

Access settings via the menu bar icon:

- **Label Theme**: Dark, Light, or Blue
- **Label Size**: Small, Medium, or Large
- **Auto-click**: Enable/disable automatic clicking on exact match

## Troubleshooting

### Hotkey not working

1. Check **System Settings > Privacy & Security > Accessibility**
2. Add Hinto.app and ensure it's checked
3. **Restart the app** after granting permission

### Check logs

```bash
make log
# or
tail -f /tmp/hinto.log
```

### Debug Options

Enable hidden debug settings via `defaults`:

```bash
# Enable file logging to /tmp/hinto.log
defaults write dev.yhao3.hinto debug-file-logging -bool true

# Enable scanner timing logs (shows performance of each scanner)
defaults write dev.yhao3.hinto debug-timing -bool true

# Disable
defaults write dev.yhao3.hinto debug-file-logging -bool false
defaults write dev.yhao3.hinto debug-timing -bool false
```

Restart the app after changing settings.

## License

MIT

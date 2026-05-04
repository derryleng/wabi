# Wabi

Wabi is a minimal macOS menubar utility for instant desktop control — no animation,
no SIP required, no Karabiner.

- **Instant space switching** — jump to any of 9 desktops via configurable hotkeys
- **Menubar toggle** — hide/show the system menubar entirely (no hover reveal)
- **Dock toggle** — disable dock hover reveal; show only on demand via hotkey
- **Built-in hotkey config** — set everything from the menubar icon

## Install

```sh
brew install --cask derryleng/tap/wabi
```

On first launch, macOS will ask for Accessibility permission. Grant it in:

> System Settings → Privacy & Security → Accessibility

Then relaunch Wabi.

## Usage

Click the grid icon in the menu bar → **Preferences…**

Assign hotkeys to any of the 9 spaces, the menubar toggle, and the dock toggle.
Click a row to record a key combo. Press Escape to cancel. Click Clear to remove.

## System Changes

When you use the **Dock hide** feature, Wabi writes these defaults:

```sh
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 999
```

These persist in your system preferences until you toggle the dock back on or uninstall.

## Uninstall

```sh
brew uninstall --cask derryleng/tap/wabi
```

If you used the dock hide feature, revert its defaults:

```sh
defaults delete com.apple.dock autohide-delay
defaults delete com.apple.dock autohide
killall Dock
```

## Why not yabai?

yabai requires disabling System Integrity Protection for most of its features.
Wabi provides the subset most people actually need — instant space switching,
menubar and dock control — without touching SIP.

## License

MIT

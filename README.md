# Wabi

Wabi is a minimal macOS menubar utility for instant desktop control — no animation,
no SIP required, no Karabiner.

- **Instant space switching** — jump to any of 9 desktops via configurable hotkeys
- **Menubar toggle** — hide/show the system menubar entirely (no hover reveal)
- **Dock toggle** — disable dock hover reveal; show only on demand via hotkey
- **Built-in hotkey config** — set everything from the menubar icon

## Install via Homebrew

```sh
brew install --cask derryleng/tap/wabi
```

## Build and install locally

```sh
git clone https://github.com/derryleng/wabi.git
cd wabi
xcodebuild \
  -scheme Wabi \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
cp -R build/Build/Products/Release/Wabi.app /Applications/
open /Applications/Wabi.app
```

## First launch

On first launch, macOS will ask for Accessibility permission. Grant it in:

> System Settings → Privacy & Security → Accessibility

Then relaunch Wabi.

## Usage

Click the grid icon in the menu bar → **Preferences…**

Assign hotkeys to any of the 9 spaces, the menubar toggle, and the dock toggle.
Click a row to record a key combo. Press Escape to cancel. Click Clear to remove.

## Uninstall

**Homebrew:**
```sh
brew uninstall --cask derryleng/tap/wabi
```

**Manual:**
```sh
rm -rf /Applications/Wabi.app
```

Wabi does not modify any system defaults. No cleanup is needed beyond removing the app.

## Why not yabai?

yabai requires disabling System Integrity Protection for most of its features.
Wabi provides the subset most people actually need — instant space switching,
menubar and dock control — without touching SIP.

## License

MIT

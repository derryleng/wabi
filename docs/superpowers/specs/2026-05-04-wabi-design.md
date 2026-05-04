# Wabi — Design Spec

**Date:** 2026-05-04
**Status:** Approved

## Overview

Wabi is a minimal macOS menubar utility that provides:

1. **Instant desktop switching** — jump to any of 9 spaces via configurable hotkeys, with no slide animation
2. **Menubar toggle** — hide/show the system menubar entirely (no hover reveal), replacing menubar-guard
3. **Dock toggle** — disable hover reveal on the dock; reveal only on demand via hotkey
4. **Launch at login** — optional, managed via SMAppService
5. **Homebrew Cask distribution** — auto-updated on tagged release via GitHub Actions

The app works without disabling System Integrity Protection (SIP). It requires a one-time Accessibility permission grant.

## Approach

- **Space switching:** CGS private API (`CGSSetActiveSpace`) — instant, no animation, no SIP required. Widely used by Hammerspoon and similar tools; stable across many macOS versions.
- **Global hotkeys:** `CGEventTap` at `kCGHIDEventTap` — same pattern as menubar-guard. Requires Accessibility permission.
- **Menubar:** `NSMenu.setMenuBarVisible(bool)` — public API, fully hides with no hover reveal.
- **Dock:** `defaults write com.apple.dock` + `killall Dock` — writes `autohide` and `autohide-delay` to system prefs; Dock restarts in under a second.

## File Structure

```
wabi/
├── .github/
│   └── workflows/
│       └── release.yml          — Build, zip, release, update homebrew-tap cask
├── Wabi/
│   ├── WabiApp.swift            — App entry, LSUIElement, menubar setup
│   ├── CGSPrivate.swift         — CGS private API declarations (@_silgen_name)
│   ├── SpaceSwitcher.swift      — Space enumeration + CGSSetActiveSpace
│   ├── MenuBarController.swift  — NSMenu.setMenuBarVisible() toggle
│   ├── DockController.swift     — Dock autohide/delay defaults + killall Dock
│   ├── HotkeyManager.swift      — CGEventTap lifecycle + event dispatch
│   ├── HotkeyRecorder.swift     — SwiftUI component for capturing key combos
│   ├── PreferencesView.swift    — Preferences window (3 sections)
│   ├── Config.swift             — UserDefaults read/write for all bindings
│   └── Assets.xcassets
├── Wabi.xcodeproj
├── README.md
└── LICENSE
```

## Components

### WabiApp.swift

- Entry point, `@main` SwiftUI App
- Sets `LSUIElement = YES` in Info.plist (no Dock icon)
- Creates `NSStatusItem` with a grid icon
- Menu: "Preferences…" (opens `PreferencesView` in a new window) and "Quit"
- On launch: calls `AXIsProcessTrustedWithOptions` — if not trusted, shows a prompt directing the user to grant Accessibility in System Settings, then exits
- Instantiates `HotkeyManager`, `SpaceSwitcher`, `MenuBarController`, `DockController`
- Restores `menubar.hidden` and `dock.hidden` state from `Config` on launch

### CGSPrivate.swift

Declares three CGS functions using `@_silgen_name` (no bridging header needed):

```swift
typealias CGSConnectionID = UInt32
typealias CGSSpaceID      = UInt64

@_silgen_name("CGSMainConnection")
func CGSMainConnection() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray

@_silgen_name("CGSSetActiveSpace")
func CGSSetActiveSpace(_ cid: CGSConnectionID, _ sid: CGSSpaceID) -> CGError
```

### SpaceSwitcher.swift

- `func switchTo(spaceIndex: Int)` (1-based)
- Calls `CGSCopyManagedDisplaySpaces` to get the current ordered space ID list
- Picks ID at `spaceIndex - 1`; silently returns if index exceeds space count
- Calls `CGSSetActiveSpace` — switches instantly with no animation

### MenuBarController.swift

- `var isHidden: Bool` (persisted in `Config`)
- `func toggle()` — calls `NSMenu.setMenuBarVisible(!isHidden)`, flips and persists state
- Called on launch to restore last state

### DockController.swift

- `var isHidden: Bool` (persisted in `Config`)
- `func toggle()`:
  - **Hide:** writes `autohide = true`, `autohide-delay = 999` to `com.apple.dock`, runs `killall Dock` (dock never auto-shows on hover)
  - **Show:** writes `autohide = false` to `com.apple.dock`, runs `killall Dock` (dock always visible, no autohide)
- Flips and persists `isHidden`
- Called on launch to restore last state

### HotkeyManager.swift

- Installs a `CGEventTap` at `kCGHIDEventTap` / `kCGHeadInsertEventTap` listening for `keyDown`
- On each event: checks key code + modifier flags against all 11 bindings from `Config`
- On match: routes to the appropriate controller and returns `nil` (swallows event)
- Non-matching events pass through unchanged
- Exposes `reload()` — called by `PreferencesView` after any binding change

### HotkeyRecorder.swift

Custom SwiftUI view:
- Displays current binding as symbols (e.g. `⌘⌥1`) or "–" if unset
- On click: enters recording mode, shows "Type shortcut…"
- Installs a local `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` to capture the next keypress
- Escape cancels recording without saving
- On capture: formats key combo, calls `Config.set(binding:for:)`, calls `HotkeyManager.reload()`
- "Clear" button removes the binding

### PreferencesView.swift

Three sections in a single window:

```
┌─────────────────────────────────────────┐
│  General                                │
│  [x] Launch at login                   │
│  ───────────────────────────────────── │
│  Spaces                                 │
│  Space 1   [ ⌘⌥1        ] [ Clear ]   │
│  Space 2   [ ⌘⌥2        ] [ Clear ]   │
│  ...                                    │
│  Space 9   [ ⌘⌥9        ] [ Clear ]   │
│  ───────────────────────────────────── │
│  System                                 │
│  Menu Bar  [ ⌘⌥M        ] [ Clear ]   │
│  Dock      [ ⌘⌥D        ] [ Clear ]   │
└─────────────────────────────────────────┘
```

Launch at login toggle calls `SMAppService.mainApp.register()` / `.unregister()`.

### Config.swift

Reads/writes all state to `UserDefaults.standard` under the `wabi.` namespace:

| Key | Type | Description |
|-----|------|-------------|
| `wabi.space.{1-9}.keyCode` | Int | CGKeyCode |
| `wabi.space.{1-9}.modifiers` | Int | CGEventFlags raw value |
| `wabi.system.menubar.keyCode` | Int | |
| `wabi.system.menubar.modifiers` | Int | |
| `wabi.system.dock.keyCode` | Int | |
| `wabi.system.dock.modifiers` | Int | |
| `wabi.menubar.hidden` | Bool | Last known menubar state |
| `wabi.dock.hidden` | Bool | Last known dock state |

Launch at login state is not stored in UserDefaults — read directly from `SMAppService.mainApp.status == .enabled`.

## Distribution

### Homebrew Cask

Added to `~/repos/homebrew-tap/Casks/wabi.rb`:

```ruby
cask "wabi" do
  version "1.0.0"
  sha256 "..."

  url "https://github.com/derryleng/wabi/releases/download/v#{version}/Wabi.zip"
  name "Wabi"
  desc "Instant desktop switcher with minimal chrome"
  homepage "https://github.com/derryleng/wabi"

  app "Wabi.app"

  caveats <<~EOS
    Wabi requires Accessibility permission to function.
    Grant access in:
      System Settings > Privacy & Security > Accessibility
  EOS
end
```

### GitHub Actions Workflow (release.yml)

Triggers on `push` to tags matching `v*.*.*`. Steps:

1. Checkout repo
2. Build with `xcodebuild -scheme Wabi -configuration Release`
3. Zip `Wabi.app` → `Wabi.zip`
4. Compute `sha256` of zip
5. Create GitHub release (via `gh release create`) and upload `Wabi.zip`
6. Checkout `homebrew-tap` repo using a `HOMEBREW_TAP_TOKEN` secret
7. Update `Casks/wabi.rb` — replace `version` and `sha256` lines
8. Commit and push to `homebrew-tap`

## README Content

The README documents:

- **Install:** `brew install --cask derryleng/tap/wabi`
- **Permissions:** one-time Accessibility permission required on first launch
- **System changes made by Wabi** (dock hidden mode):
  - `defaults write com.apple.dock autohide -bool true`
  - `defaults write com.apple.dock autohide-delay -float 999`
- **Uninstall:**
  ```sh
  brew uninstall derryleng/tap/wabi
  # Revert dock defaults if you used the dock hide feature:
  defaults delete com.apple.dock autohide-delay
  defaults delete com.apple.dock autohide
  killall Dock
  ```
- **Usage:** hotkey configuration via menubar icon → Preferences
- **Comparison with yabai/menubar-guard:** works without SIP disabled; self-contained hotkey config

## Permissions Required

| Permission | Why |
|-----------|-----|
| Accessibility | CGEventTap for global hotkeys |

No other entitlements or sandbox exceptions needed. The app is not sandboxed (sandboxing would block CGEventTap and `killall Dock`).

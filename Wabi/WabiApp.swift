import SwiftUI
import AppKit
import ApplicationServices

@main
struct WabiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var spaceSwitcher: SpaceSwitcher!
    private var menuBarController: MenuBarController!
    private var dockController: DockController!
    private var hotkeyManager: HotkeyManager!
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibility()
        spaceSwitcher    = SpaceSwitcher()
        menuBarController = MenuBarController()   // restores menubar hidden state
        dockController   = DockController()       // reads dock hidden state (no killall)
        hotkeyManager    = HotkeyManager(
            spaceSwitcher: spaceSwitcher,
            menuBarController: menuBarController,
            dockController: dockController
        )
        setupStatusItem()
    }

    // MARK: - Accessibility

    private func checkAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        guard !trusted else { return }

        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            Wabi needs Accessibility access to register global hotkeys.

            Grant access in:
            System Settings → Privacy & Security → Accessibility

            Then relaunch Wabi.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
        NSApp.terminate(nil)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "square.grid.2x2",
                               accessibilityDescription: "Wabi")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences…",
                                action: #selector(openPreferences),
                                keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Wabi",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - Preferences Window

    @objc private func openPreferences() {
        if let win = preferencesWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PreferencesView(onBindingsChanged: { [weak self] in
            self?.hotkeyManager.reload()
        })
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Wabi"
        win.contentView = NSHostingView(rootView: view)
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow = win
    }

    func windowWillClose(_ notification: Notification) {
        preferencesWindow = nil
    }
}

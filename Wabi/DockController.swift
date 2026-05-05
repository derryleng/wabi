import Foundation
import AppKit
import os

final class DockController {
    private(set) var isHidden: Bool
    private let hoverBlocker: HoverBlocker

    init(hoverBlocker: HoverBlocker) {
        self.hoverBlocker = hoverBlocker
        isHidden = Config.dockHidden()
        // Re-apply hide state via CoreDock if needed (no Dock restart — no flash).
        // The plist was already written in the previous session so the Dock itself
        // came up with the right autohide value; we just need to block hover.
        if isHidden { hoverBlocker.dockBlocked = true }
    }

    func toggle() {
        isHidden.toggle()
        isHidden ? applyHide() : applyShow()
        Config.setDockHidden(isHidden)
    }

    // MARK: - Private

    private func applyHide() {
        // 1. Persist autohide preference so the Dock reads it correctly on next restart.
        writeAutohideDefault(true)
        // 2. Apply to the running Dock immediately — no restart, no flash.
        coreDockSetAutoHide(true)
        // 3. Block cursor from entering the dock edge to prevent hover reveal.
        hoverBlocker.dockBlocked = true
    }

    private func applyShow() {
        writeAutohideDefault(false)
        coreDockSetAutoHide(false)
        hoverBlocker.dockBlocked = false
        // Dock appears immediately — no hover needed, no delay.
    }

    /// Write the autohide preference to disk WITHOUT restarting the Dock.
    /// CoreDockSetAutoHide handles the live state; this just persists for restarts.
    private func writeAutohideDefault(_ enabled: Bool) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        p.arguments = ["write", "com.apple.dock", "autohide",
                       "-bool", enabled ? "true" : "false"]
        do {
            try p.run(); p.waitUntilExit()
        } catch {
            os_log(.error, "DockController: defaults write failed: %{public}@",
                   error.localizedDescription)
        }
    }
}

// MARK: - CoreDock private API

private let _coreDockHandle: UnsafeMutableRawPointer? = dlopen(
    "/System/Library/PrivateFrameworks/CoreDock.framework/CoreDock", RTLD_LAZY
)

/// Toggle dock autohide via the CoreDock private framework.
/// This takes effect immediately in the running Dock process with no restart and no flash.
private func coreDockSetAutoHide(_ enabled: Bool) {
    typealias Fn = @convention(c) (Bool) -> Void
    guard let sym = dlsym(_coreDockHandle, "CoreDockSetAutoHide") else {
        os_log(.error, "DockController: CoreDockSetAutoHide not found in CoreDock framework")
        return
    }
    unsafeBitCast(sym, to: Fn.self)(enabled)
}

import AppKit
import os

final class DockController {
    private(set) var isHidden: Bool
    private let hoverBlocker: HoverBlocker

    init(hoverBlocker: HoverBlocker) {
        self.hoverBlocker = hoverBlocker
        isHidden = Config.dockHidden()
        // Re-apply hide state on relaunch via CoreDock (no Dock restart, no flash).
        if isHidden {
            coreDockSetAutoHide(true)
            hoverBlocker.dockBlocked = true
        }
    }

    func toggle() {
        isHidden.toggle()
        isHidden ? applyHide() : applyShow()
        Config.setDockHidden(isHidden)
    }

    // MARK: - Private

    private func applyHide() {
        coreDockSetAutoHide(true)
        hoverBlocker.dockBlocked = true
    }

    private func applyShow() {
        coreDockSetAutoHide(false)
        hoverBlocker.dockBlocked = false
    }
}

// MARK: - CoreDock private API

private let _coreDockHandle: UnsafeMutableRawPointer? = dlopen(
    "/System/Library/PrivateFrameworks/CoreDock.framework/CoreDock", RTLD_LAZY
)

/// Toggle dock autohide via the CoreDock private framework.
/// Takes effect immediately in the running Dock process — no restart, no flash,
/// no changes to com.apple.dock defaults.
private func coreDockSetAutoHide(_ enabled: Bool) {
    typealias Fn = @convention(c) (Bool) -> Void
    guard let sym = dlsym(_coreDockHandle, "CoreDockSetAutoHide") else {
        os_log(.error, "DockController: CoreDockSetAutoHide not found in CoreDock framework")
        return
    }
    unsafeBitCast(sym, to: Fn.self)(enabled)
}

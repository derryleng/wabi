import Foundation

final class DockController {
    private(set) var isHidden: Bool

    init() {
        // Read last known state; do NOT re-apply on launch to avoid
        // an unnecessary killall Dock — system prefs already reflect the state.
        isHidden = Config.dockHidden()
    }

    func toggle() {
        isHidden.toggle()
        apply()
        Config.setDockHidden(isHidden)
    }

    private func apply() {
        if isHidden {
            runDefaults(["write", "com.apple.dock", "autohide", "-bool", "true"])
            // 999s delay means hover never triggers auto-reveal
            runDefaults(["write", "com.apple.dock", "autohide-delay", "-float", "999"])
        } else {
            runDefaults(["write", "com.apple.dock", "autohide", "-bool", "false"])
        }
        killallDock()
    }

    private func runDefaults(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
    }

    private func killallDock() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        p.arguments = ["Dock"]
        try? p.run()
        p.waitUntilExit()
    }
}

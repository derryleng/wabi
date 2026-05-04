import CoreGraphics
import Foundation

enum Config {
    private static func key(for target: HotkeyTarget) -> String {
        switch target {
        case .space(let n): return "wabi.space.\(n)"
        case .menuBar:      return "wabi.system.menubar"
        case .dock:         return "wabi.system.dock"
        }
    }

    static func binding(for target: HotkeyTarget, defaults: UserDefaults = .standard) -> HotkeyBinding? {
        let base = key(for: target)
        guard defaults.object(forKey: "\(base).keyCode") != nil else { return nil }
        let keyCode = UInt16(defaults.integer(forKey: "\(base).keyCode"))
        let raw = UInt64(bitPattern: Int64(defaults.integer(forKey: "\(base).modifiers")))
        return HotkeyBinding(keyCode: keyCode, modifiers: CGEventFlags(rawValue: raw))
    }

    static func setBinding(_ binding: HotkeyBinding?, for target: HotkeyTarget, defaults: UserDefaults = .standard) {
        let base = key(for: target)
        if let b = binding {
            defaults.set(Int(b.keyCode), forKey: "\(base).keyCode")
            defaults.set(Int(bitPattern: UInt(b.modifiers.rawValue)), forKey: "\(base).modifiers")
        } else {
            defaults.removeObject(forKey: "\(base).keyCode")
            defaults.removeObject(forKey: "\(base).modifiers")
        }
    }

    static func menuBarHidden(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: "wabi.menubar.hidden")
    }

    static func setMenuBarHidden(_ hidden: Bool, defaults: UserDefaults = .standard) {
        defaults.set(hidden, forKey: "wabi.menubar.hidden")
    }

    static func dockHidden(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: "wabi.dock.hidden")
    }

    static func setDockHidden(_ hidden: Bool, defaults: UserDefaults = .standard) {
        defaults.set(hidden, forKey: "wabi.dock.hidden")
    }
}

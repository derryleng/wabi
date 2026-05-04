import AppKit

final class MenuBarController {
    private(set) var isHidden: Bool

    init() {
        isHidden = Config.menuBarHidden()
        apply()
    }

    func toggle() {
        isHidden.toggle()
        apply()
        Config.setMenuBarHidden(isHidden)
    }

    private func apply() {
        NSMenu.setMenuBarVisible(!isHidden)
    }
}

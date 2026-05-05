import AppKit

final class MenuBarController {
    private(set) var isHidden: Bool
    private let hoverBlocker: HoverBlocker

    init(hoverBlocker: HoverBlocker) {
        self.hoverBlocker = hoverBlocker
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
        hoverBlocker.menuBarBlocked = isHidden
    }
}

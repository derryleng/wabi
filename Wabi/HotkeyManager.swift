import CoreGraphics
import AppKit

final class HotkeyManager {
    private let spaceSwitcher: SpaceSwitcher
    private let menuBarController: MenuBarController
    private let dockController: DockController
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(spaceSwitcher: SpaceSwitcher,
         menuBarController: MenuBarController,
         dockController: DockController) {
        self.spaceSwitcher = spaceSwitcher
        self.menuBarController = menuBarController
        self.dockController = dockController
        install()
    }

    // Call after any binding change in Preferences to re-enable the tap
    // if macOS disabled it (it auto-disables if events back up)
    func reload() {
        guard let tap = eventTap, !CGEvent.tapIsEnabled(tap: tap) else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func install() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return mgr.handle(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap = eventTap else {
            print("Wabi: failed to create CGEventTap — Accessibility permission missing?")
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType,
                        event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keyCode   = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = event.flags.intersection(.relevant)

        let targets: [HotkeyTarget] = (1...9).map { .space($0) } + [.menuBar, .dock]
        for target in targets {
            guard let b = Config.binding(for: target) else { continue }
            guard b.keyCode == keyCode,
                  b.modifiers.intersection(.relevant) == modifiers else { continue }
            DispatchQueue.main.async { [weak self] in
                self?.dispatch(target: target)
            }
            return nil  // swallow the event
        }
        return Unmanaged.passUnretained(event)
    }

    private func dispatch(target: HotkeyTarget) {
        switch target {
        case .space(let n): spaceSwitcher.switchTo(spaceIndex: n)
        case .menuBar:      menuBarController.toggle()
        case .dock:         dockController.toggle()
        }
    }
}

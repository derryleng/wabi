import CoreGraphics
import AppKit

/// Prevents the cursor from straying into the menu-bar zone (top of screen) and/or
/// the dock zone (bottom of screen) by clamping mouse-move events in-place via
/// CGEventSetLocation — the same technique used by menubar-guard.
///
/// Clamping in-place is critical: suppressing the event and calling
/// CGWarpMouseCursorPosition instead causes the HID layer to accumulate deltas
/// against y=0, making the cursor appear frozen until the physical mouse travels
/// far enough to repay the "debt."
final class HoverBlocker {
    /// Threshold in display-points from the edge of the primary screen.
    private static let edgeThreshold: CGFloat = 4

    var menuBarBlocked = false { didSet { updateTap() } }
    var dockBlocked    = false { didSet { updateTap() } }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var needsTap: Bool { menuBarBlocked || dockBlocked }

    // MARK: - Tap lifecycle

    private func updateTap() {
        needsTap ? installIfNeeded() : removeTap()
    }

    private func installIfNeeded() {
        if let tap = eventTap {
            if !CGEvent.tapIsEnabled(tap: tap) { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        let mask: CGEventMask =
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue)  |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                Unmanaged<HoverBlocker>.fromOpaque(refcon).takeUnretainedValue()
                    .clamp(event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap = eventTap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Clamping

    private func clamp(event: CGEvent) {
        let screenH = CGDisplayBounds(CGMainDisplayID()).size.height
        var pt = event.location
        let t  = HoverBlocker.edgeThreshold

        if menuBarBlocked && pt.y < t     { pt.y = t }
        if dockBlocked    && pt.y > screenH - t { pt.y = screenH - t }

        CGEventSetLocation(event, pt)  // mutate in-place; caller returns same event
    }

    deinit { removeTap() }
}

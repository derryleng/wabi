import XCTest
import CoreGraphics
@testable import Wabi

final class ConfigTests: XCTestCase {
    private let suiteName = "WabiConfigTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testSpaceBindingRoundTrip() {
        let binding = HotkeyBinding(keyCode: 18, modifiers: [.maskCommand, .maskAlternate])
        Config.setBinding(binding, for: .space(1), defaults: defaults)
        XCTAssertEqual(Config.binding(for: .space(1), defaults: defaults), binding)
    }

    func testClearBindingReturnsNil() {
        let binding = HotkeyBinding(keyCode: 18, modifiers: [.maskCommand])
        Config.setBinding(binding, for: .space(1), defaults: defaults)
        Config.setBinding(nil, for: .space(1), defaults: defaults)
        XCTAssertNil(Config.binding(for: .space(1), defaults: defaults))
    }

    func testMenuBarBindingRoundTrip() {
        let binding = HotkeyBinding(keyCode: 46, modifiers: [.maskCommand, .maskAlternate])
        Config.setBinding(binding, for: .menuBar, defaults: defaults)
        XCTAssertEqual(Config.binding(for: .menuBar, defaults: defaults), binding)
    }

    func testDockBindingRoundTrip() {
        let binding = HotkeyBinding(keyCode: 2, modifiers: [.maskCommand, .maskAlternate])
        Config.setBinding(binding, for: .dock, defaults: defaults)
        XCTAssertEqual(Config.binding(for: .dock, defaults: defaults), binding)
    }

    func testUnsetBindingReturnsNil() {
        XCTAssertNil(Config.binding(for: .space(5), defaults: defaults))
    }

    func testAllNineSpaceTargetsAreIndependent() {
        for n in 1...9 {
            let b = HotkeyBinding(keyCode: UInt16(n), modifiers: [.maskCommand])
            Config.setBinding(b, for: .space(n), defaults: defaults)
        }
        for n in 1...9 {
            XCTAssertEqual(Config.binding(for: .space(n), defaults: defaults)?.keyCode, UInt16(n))
        }
    }

    func testMenuBarHiddenDefaultsFalse() {
        XCTAssertFalse(Config.menuBarHidden(defaults: defaults))
    }

    func testMenuBarHiddenPersists() {
        Config.setMenuBarHidden(true, defaults: defaults)
        XCTAssertTrue(Config.menuBarHidden(defaults: defaults))
        Config.setMenuBarHidden(false, defaults: defaults)
        XCTAssertFalse(Config.menuBarHidden(defaults: defaults))
    }

    func testDockHiddenDefaultsFalse() {
        XCTAssertFalse(Config.dockHidden(defaults: defaults))
    }

    func testDockHiddenPersists() {
        Config.setDockHidden(true, defaults: defaults)
        XCTAssertTrue(Config.dockHidden(defaults: defaults))
    }
}

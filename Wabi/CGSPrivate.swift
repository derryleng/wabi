import CoreGraphics
import Foundation

typealias CGSConnectionID = UInt32
typealias CGSSpaceID      = UInt64

// Links to private symbols in the CoreGraphics framework.
// These have been stable across many macOS versions (10.x–15.x).
//
// CGSCopyManagedDisplaySpaces is exported in the SDK stub and can use @_silgen_name.
// CGSMainConnection and CGSSetActiveSpace are not in the SDK stub, so we resolve
// them via dlsym against the live CoreGraphics dylib.

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray

private let _cgHandle: UnsafeMutableRawPointer? = dlopen(
    "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY
)

func CGSMainConnection() -> CGSConnectionID {
    typealias Fn = @convention(c) () -> CGSConnectionID
    guard let sym = dlsym(_cgHandle, "CGSMainConnection") else { return 0 }
    return unsafeBitCast(sym, to: Fn.self)()
}

@discardableResult
func CGSSetActiveSpace(_ cid: CGSConnectionID, _ sid: CGSSpaceID) -> CGError {
    typealias Fn = @convention(c) (CGSConnectionID, CGSSpaceID) -> CGError
    guard let sym = dlsym(_cgHandle, "CGSSetActiveSpace") else { return .failure }
    return unsafeBitCast(sym, to: Fn.self)(cid, sid)
}

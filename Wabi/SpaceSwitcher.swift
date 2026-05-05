import CoreGraphics
import Foundation

final class SpaceSwitcher {
    func switchTo(spaceIndex: Int) {
        let cid = CGSMainConnection()
        guard cid != 0 else { return }
        let ids = userSpaceIDs(cid: cid)
        let index = spaceIndex - 1
        guard index >= 0, index < ids.count else { return }
        CGSSetActiveSpace(cid, ids[index])
    }

    private func userSpaceIDs(cid: CGSConnectionID) -> [CGSSpaceID] {
        // CGSCopyManagedDisplaySpaces returns a CFArray of CFDictionaries.
        // Cast via NSArray/NSDictionary (not [[String:Any]]) to avoid Swift's
        // strict bridge check failing when CoreFoundation stores ids as Int64
        // NSNumber rather than UInt64 NSNumber — then use .uint64Value explicitly.
        let raw = CGSCopyManagedDisplaySpaces(cid) as NSArray
        var ids: [CGSSpaceID] = []
        for item in raw {
            guard let display = item as? NSDictionary,
                  let spaces = display["Spaces"] as? NSArray else { continue }
            for spaceItem in spaces {
                guard let space = spaceItem as? NSDictionary,
                      let type  = (space["type"]  as? NSNumber)?.intValue, type == 0,
                      let id    = (space["id64"]  as? NSNumber)?.uint64Value
                else { continue }
                ids.append(id)
            }
        }
        return ids
    }
}

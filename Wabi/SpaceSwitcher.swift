import CoreGraphics
import Foundation

final class SpaceSwitcher {
    func switchTo(spaceIndex: Int) {
        let cid = CGSMainConnection()
        let ids = userSpaceIDs(cid: cid)
        let index = spaceIndex - 1
        guard index >= 0, index < ids.count else { return }
        CGSSetActiveSpace(cid, ids[index])
    }

    private func userSpaceIDs(cid: CGSConnectionID) -> [CGSSpaceID] {
        let raw = CGSCopyManagedDisplaySpaces(cid) as NSArray
        guard let displays = raw as? [[String: Any]] else { return [] }
        var ids: [CGSSpaceID] = []
        for display in displays {
            guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }
            for space in spaces {
                // type 0 = normal user space; skip fullscreen (2) and dashboard (4)
                guard let id   = space["id64"] as? CGSSpaceID,
                      let type = space["type"] as? Int,
                      type == 0 else { continue }
                ids.append(id)
            }
        }
        return ids
    }
}

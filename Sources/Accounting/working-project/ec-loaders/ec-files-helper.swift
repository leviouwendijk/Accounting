import Foundation

internal func ecFiles(at root: URL) -> [URL] {
    let fm = FileManager.default
    guard let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
    var urls: [URL] = []
    while let next = e.nextObject() as? URL {
        if next.pathExtension == "ec" {
            urls.append(next)
        }
    }
    return urls
}

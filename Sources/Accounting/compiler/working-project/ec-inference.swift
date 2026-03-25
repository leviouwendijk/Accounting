import Foundation

// ===============================================
// Inference from file path (pass to parseEntityBlock)
// ===============================================
/// Example: config/entities/objects/usable.ec → ("objects","usable")
// public func inferClassFamily(from fileURL: URL) -> (String?, String?) {
//     let comps = fileURL.deletingPathExtension().pathComponents
//     guard let i = comps.lastIndex(of: "entities") else { return (nil, nil) }
//     let tail = comps[(i+1)...] // ["objects","usable"] or ["people","owners"] etc
//     let cls = tail.first
//     let fam = tail.dropFirst().last
//     return (cls, fam)
// }

/// modification: allowing subnesting dirs and files
//  config/entities/objects/usable.ec → ("objects","usable")
public func inferClassFamily(from fileURL: URL) -> (String?, String?) {
    let comps = fileURL.deletingPathExtension().pathComponents
    guard let i = comps.lastIndex(of: "entities") else { return (nil, nil) }
    let tail = comps[(i+1)...]             // e.g. ["objects","usable","foo"]
    let cls = tail.first                   // "objects"
    let fam = tail.dropFirst().first       // "usable"  (ignore deeper)
    return (cls, fam)
}

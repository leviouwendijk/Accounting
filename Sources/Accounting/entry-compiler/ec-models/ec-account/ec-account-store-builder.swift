import Foundation

// public struct AccountStoreBuilder {
//     private var base: [String: RGSAccount] = [:]
//     private var overrides: [String: AccountDef] = [:]

//     public init() {}

//     public mutating func addBase(_ accounts: [RGSAccount]) throws {
//         for a in accounts {
//             if base.updateValue(a, forKey: a.code) != nil {
//                 throw AccountStoreError.duplicateCode(a.code, at: nil)
//             }
//         }
//     }

//     public mutating func addOverride(_ def: AccountDef) {
//         overrides[def.code] = def
//     }

//     public mutating func addOverrides(_ defs: [AccountDef]) throws {
//         for d in defs { addOverride(d) }
//     }

//     public func freeze() throws -> AccountStore {
//         var out = base

//         for (code, ov) in overrides {
//             if var b = out[code] {
//                 if let lbl = ov.label      { b = RGSAccount(code: b.code, label: lbl, level: b.level, direction: b.direction, identifiers: b.identifiers, applicability: b.applicability) }
//                 if let dir = ov.direction  { b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: dir,     identifiers: b.identifiers, applicability: b.applicability) }
//                 if let lvl = ov.level      { b = RGSAccount(code: b.code, label: b.label, level: lvl,     direction: b.direction, identifiers: b.identifiers, applicability: b.applicability) }
//                 if let ids = ov.identifiers{ b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: b.direction, identifiers: ids, applicability: b.applicability) }
//                 if let app = ov.applicability { b = RGSAccount(code: b.code, label: b.label, level: b.level, direction: b.direction, identifiers: b.identifiers, applicability: app) }
//                 out[code] = b
//             } else {
//                 guard
//                     let lbl = ov.label,
//                     let dir = ov.direction,
//                     let lvl = ov.level
//                 else {
//                     throw AccountStoreError.missingRequiredForNewAccount(
//                         code: code,
//                         missing: ["label": ov.label == nil, "direction": ov.direction == nil, "level": ov.level == nil]
//                             .compactMap { $0.value ? $0.key : nil }
//                             .joined(separator: ", "),
//                         at: nil
//                     )
//                 }
//                 let ids = ov.identifiers ?? RGSIdentifiers(rgs: code, omslag: nil)
//                 let app = ov.applicability ?? Applicability(zzp: "", ez: "", bv: "", svc: "", branche: "")
//                 out[code] = RGSAccount(code: code, label: lbl, level: lvl, direction: dir, identifiers: ids, applicability: app)
//             }
//         }

//         return try AccountStore(Array(out.values))
//     }
// }

import Foundation

/// Minimal builder for a node-backed AccountStore.
/// Prefer `useChart(_:)` so identifier lookups are enabled.
public struct AccountStoreBuilder {
    private var chart: CompiledChart?
    private var nodesOnly: [RGSNode] = []

    public init() {}

    /// Use a compiled chart (nodes + identifier index). Preferred.
    public mutating func useChart(_ chart: CompiledChart) {
        self.chart = chart
        self.nodesOnly = [] // clear nodes-only if present
    }

    /// Fallback: use a plain node list (identifier lookups disabled).
    public mutating func useNodes(_ nodes: [RGSNode]) {
        self.nodesOnly = nodes
        self.chart = nil
    }

    // Legacy override API (RGSAccount/AccountDef) removed for node-backed store.
    // If you still need project-level presentation overrides, model them separately
    // (e.g., a PresentationOverrides map keyed by code) and apply during rendering.

    public func freeze() throws -> AccountStore {
        if let c = chart {
            return try AccountStore(chart: c)
        } else if !nodesOnly.isEmpty {
            return try AccountStore(nodes: nodesOnly)
        } else {
            throw AccountStoreError.empty(at: nil)
        }
    }
}

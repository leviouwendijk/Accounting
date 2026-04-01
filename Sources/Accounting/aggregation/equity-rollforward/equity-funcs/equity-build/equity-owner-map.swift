import Foundation

@inline(__always)
public func normalizeInlineDisplayText(
    _ text: String
) -> String {
    let collapsed = text
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")

    return collapsed.trimmingCharacters(
        in: .whitespacesAndNewlines
    )
}

public func ownerNameMap(
    _ entities: EntityStore
) -> [Int?: String] {
    var out: [Int?: String] = [
        nil: "(unassigned)"
    ]

    for (key, id) in entities.idIndex {
        let fallback = key.identifier(displaying: .fullchain)
        let raw = entities.byFull[key]?.displayName ?? fallback
        let normalized = normalizeInlineDisplayText(raw)

        out[id] = normalized.isEmpty
            ? fallback
            : normalized
    }

    return out
}

/// AE → owner map for a single account code
public func aeMap(
    bundle: StatementBundle,
    code: String,
    maps: ChartMaps
) -> [Int: Decimal] {
    guard let eb = bundle.entity?.byAccount,
          let id = maps.idByCode[code],
          let m  = eb[id]
    else {
        return [:]
    }

    return Dictionary(
        uniqueKeysWithValues: m.compactMap { (eid, amt) in
            guard let oid = eid else {
                return nil
            }

            return (oid, amt)
        }
    )
}

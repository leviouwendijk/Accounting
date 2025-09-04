import Foundation

extension RGSAssembler {
    // public static func assertEdgesMatchKeys(_ maps: RGSAssemblerResult) {
    //     var bad: [(Int,String,String)] = []
    //     for (child, parent) in maps.parentById {
    //         guard
    //             let ck = maps.sortKeyById[child],
    //             let pk = maps.sortKeyById[parent],
    //             let cpk = RGSNodeSortingCode(key: ck).parentKeyString
    //         else { continue }
    //         if cpk != pk {
    //             bad.append((child, ck, pk))
    //         }
    //     }
    //     if !bad.isEmpty {
    //         fputs("RGS edge/key mismatches: \(bad.count)\n", stderr)
    //         for (id, ck, pk) in bad.prefix(20) {
    //             fputs("  id=\(id) childKey='\(ck)' parentKey='\(pk)'\n", stderr)
    //         }
    //     }
    // }

    @available(*, deprecated, message: "SortingKey is order-only; this check is informational only.")
    public static func assertEdgesMatchKeys(_ maps: RGSAssemblerResult) {
        // Only run if explicitly enabled (e.g. EC_CHECK_SORTKEY_EDGES=1)
        guard ProcessInfo.processInfo.environment["EC_CHECK_SORTKEY_EDGES"] == "1" else { return }

        var bad: [(Int,String,String)] = []
        for (child, parent) in maps.parentById {
            guard
                let ck = maps.sortKeyById[child],
                let pk = maps.sortKeyById[parent],
                let cpk = RGSNodeSortingCode(key: ck).parentKeyString
            else { continue }
            if cpk != pk {
                bad.append((child, ck, pk))
            }
        }
        if !bad.isEmpty {
            fputs("RGS edge/key mismatches: \(bad.count)\n", stderr)
            for (id, ck, pk) in bad.prefix(20) {
                fputs("  id=\(id) childKey='\(ck)' parentKey='\(pk)'\n", stderr)
            }
        }
    }

    @inline(__always)
    public static func assertSeedSumsToZero(_ seed: [Int: Decimal]) throws {
        let sum = seed.values.reduce(0, +)
        if sum != 0 { throw RGSAssemblerError.seedTotalsNotZero(sum) }
    }
}

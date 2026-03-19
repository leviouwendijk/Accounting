extension OwnerEquity.Rollforward {
    public static func printDiagnostics(
        _ diagnostics: [EquityDiagnostic],
        entities: EntityStore
    ) {
        guard !diagnostics.isEmpty else {
            return
        }

        let names = ownerNameMap(entities)

        for diagnostic in diagnostics {
            let tag: String = {
                switch diagnostic.kind {
                case .info:
                    return "INFO"
                case .warning:
                    return "WARNING"
                case .assertion:
                    return "ASSERT"
                }
            }()

            if let periodLabel = diagnostic.periodLabel {
                print("[\(tag)] [\(periodLabel)] \(diagnostic.message)")
            } else {
                print("[\(tag)] \(diagnostic.message)")
            }

            switch diagnostic.payload {
            case .none:
                break

            case .ownerMap(let map):
                let total = map.values.reduce(0, +)
                print("    total = \(fmtDec(total))")

                for oid in map.keys.sorted() {
                    let name = names[Int?(oid)] ?? "owner#\(oid)"
                    let amount = map[oid] ?? 0
                    print("    - \(name): \(fmtDec(amount))")
                }
            }
        }
    }
}

import Foundation

public extension EntryCompilerParsing {
    /// Attach lightweight readers inside your existing parseDepreciationBlock() switch.
    @inlinable
    func parseDepreciationRollforward(into meta: inout [String:String], tz: TimeZone = .current) -> Bool {
        guard current == .ident("rollforward") else { return false }
        advance(); try? beginBlock()
        var idx = 0

        func parseEvent(kind: String) {
            advance(); try? beginBlock()
            var dateStr: String?
            var amount: String?
            var linked: [Int] = []
            var reason: String?

            while current != .rBrace && current != .eof {
                switch current {
                case .ident("effective_date"):
                    advance(); try? expect(.equals)
                    switch current {
                    case let .dateLiteral(text):
                        if let d = try? parseDateLiteral(text, in: tz) { dateStr = ISO8601DateFormatter().string(from: d) }
                        advance()
                    case .lBrace:
                        if let d = try? parseDateBlock(tz: tz) { dateStr = ISO8601DateFormatter().string(from: d) }
                    default: break
                    }
                case .ident("amount"), .ident("value"):
                    advance(); try? expect(.equals)
                    if case let .number(n) = current { amount = "\(n)"; advance() }
                case .ident("linked_entry"), .ident("linked_entries"):
                    advance(); try? expect(.equals)
                    var tmp: [Int] = []; try? parseIntList(into: &tmp)
                    linked = tmp
                case .ident("details"), .ident("reason"):
                    reason = (try? parseFreeTextBlock(named: "details")) ?? reason
                default:
                    break
                }
            }
            _ = try? endBlock()

            if let d = dateStr { meta["dep.rollforward.\(idx).date"] = d }
            if let a = amount { meta["dep.rollforward.\(idx).amount"] = a }
            if !linked.isEmpty { meta["dep.rollforward.\(idx).linked"] = linked.map(String.init).joined(separator: ",") }
            if let r = reason { meta["dep.rollforward.\(idx).reason"] = r }
            meta["dep.rollforward.\(idx).kind"] = kind
            idx += 1
        }

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("capex"):
                parseEvent(kind: "capex")
            case .ident("revision"):
                parseEvent(kind: "revision")
            default:
                break
            }
        }
        _ = try? endBlock()
        return true
    }

    /// Optional readers you referenced in your keywords list:
    @inlinable
    func parseDepreciationValuation(into meta: inout [String:String]) -> Bool {
        guard current == .ident("valuation") else { return false }
        advance(); try? beginBlock()
        while current != .rBrace && current != .eof {
            guard current == .ident("acquisition_cost") else { break }
            advance(); try? beginBlock()
            while current != .rBrace && current != .eof {
                switch current {
                case .ident("direct"):
                    advance(); try? expect(.equals)
                    if case let .number(n) = current { meta["dep.valuation.acquisition.direct"] = "\(n)"; advance() }
                case .ident("indirect"):
                    advance(); try? expect(.equals)
                    if case let .number(n) = current { meta["dep.valuation.acquisition.indirect"] = "\(n)"; advance() }
                default: break
                }
            }
            _ = try? endBlock()
        }
        _ = try? endBlock()
        return true
    }

    @inlinable
    func parseUsefulLifeMonths(into meta: inout [String:String]) -> Bool {
        guard current == .ident("useful_life_months") else { return false }
        advance(); try? expect(.equals)
        if case let .number(n) = current { meta["dep.useful_life_months"] = "\(n)"; advance(); return true }
        return false
    }
}

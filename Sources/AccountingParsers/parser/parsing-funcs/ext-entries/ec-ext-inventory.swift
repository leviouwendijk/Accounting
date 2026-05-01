import Foundation
import Accounting

public extension EntryCompilerParsing {
    func parseSingleInventoryAdjustment(after tok: EntryCompilerToken? = nil) throws -> InventoryAdjustment {
        let t = tok ?? current
        let isAdd = (t == .keyword("adding") || t == .keyword("addition") || t == .keyword("add"))
        let isRed = (t == .keyword("removing") || t == .keyword("reduction") || t == .keyword("remove") || t == .keyword("rm"))
        guard isAdd || isRed else {
            throw ParserError.unexpectedToken(current, expected: "inventory adjustment keyword", at: loc())
        }
        if tok == nil { advance() }
        try expect(.equals)
        guard case let .number(qDec) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        let qty = (qDec as NSDecimalNumber).doubleValue
        advance()
        return InventoryAdjustment(mutation: isAdd ? .addition : .reduction, count: qty)
    }

    func parseInventoryBlock() throws -> InventoryAdjustment {
        try expect(.keyword("inventory"))
        try expect(.lBrace)

        var net: Double = 0.0
        var pendingMutation: InventoryAdjustmentDirection?
        var pendingCount: Double?

        func flushPendingIfReady() {
            if let m = pendingMutation, let c = pendingCount {
                net += (m == .addition ? c : -c)
                pendingMutation = nil
                pendingCount = nil
            }
        }

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("addition"), .keyword("adding"), .keyword("add"),
                 .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"):
                let adj = try parseSingleInventoryAdjustment()
                net += (adj.mutation == .addition ? adj.count : -adj.count)

            case .ident("mutation"):
                advance(); try expect(.equals)
                switch current {
                case .keyword("addition"), .keyword("adding"), .keyword("add"): pendingMutation = .addition
                case .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"): pendingMutation = .reduction
                default:
                    throw ParserError.unexpectedToken(current, expected: "add/remove", at: loc())
                }
                advance(); flushPendingIfReady()

            case .ident("count"):
                advance(); try expect(.equals)
                guard case let .number(qDec) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                pendingCount = (qDec as NSDecimalNumber).doubleValue
                advance(); flushPendingIfReady()

            default:
                throw ParserError.unexpectedToken(current, expected: "inventory field", at: loc())
            }
        }

        try expect(.rBrace)
        if (pendingMutation != nil) != (pendingCount != nil) {
            throw ParserError.unexpectedToken(current, expected: "both mutation and count", at: loc())
        }
        let finalDir: InventoryAdjustmentDirection = (net >= 0) ? .addition : .reduction
        let finalCount = abs(net)
        return InventoryAdjustment(mutation: finalDir, count: finalCount)
    }
}

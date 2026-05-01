import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inline(__always)
    func readNameWithVariantChain() throws -> String {
        let base0: String
        switch current {
        case let .ident(s), let .entity(s), let .account(s):
            base0 = s
            advance()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "identifier",
                at: loc()
            )
        }

        var s = base0

        while current == .hash {
            advance() // eat '#'

            var variant = ""
            var sawAny = false

            variantLoop: while true {
                switch current {
                case let .ident(v), let .entity(v), let .account(v):
                    variant += v
                    sawAny = true
                    advance()

                case let .number(n):
                    variant += String(describing: n)
                    sawAny = true
                    advance()

                default:
                    break variantLoop
                }
            }

            guard sawAny else {
                throw ParserError.unexpectedToken(
                    current,
                    expected: "identifier or number after '#'",
                    at: loc()
                )
            }

            s.append("#")
            s.append(variant)
        }

        return s
    }

    /// Consume a contiguous run of ident/number/entity/account tokens into a single string.
    @inline(__always)
    func readIdentOrNumberRun(requireAtLeastOne: Bool = true) throws -> String {
        var out = ""
        var saw = false

        while true {
            switch current {
            case let .ident(s), let .entity(s), let .account(s):
                out += s
                saw = true
                advance()

            case let .number(n):
                out += String(describing: n)
                saw = true
                advance()

            default:
                break
            }

            switch current {
            case .ident, .number, .entity, .account:
                continue

            default:
                break
            }

            break
        }

        if requireAtLeastOne && !saw {
            throw ParserError.unexpectedToken(
                current,
                expected: "identifier or number",
                at: loc()
            )
        }

        return out
    }

    /// Like `readNameWithVariantChain` but allows a number as the first token.
    /// Example: `15_pro_max#rev2`
    @inline(__always)
    func readAliasFlexible() throws -> String {
        var name = try readIdentOrNumberRun(requireAtLeastOne: true)

        while current == .hash {
            advance()
            let v = try readIdentOrNumberRun(requireAtLeastOne: true)
            name.append("#")
            name.append(v)
        }

        return name
    }

    // Atom: ident[#…] | entity[#…] | account[#…] | number | unit(<id|number>)
    @inline(__always)
    func readAtomSegment() throws -> String {
        switch current {
        case .keyword("inventory"):
            throw ParserError.deprecatedPathSegment(
                segment: "inventory",
                suggestion: "objects.storable",
                at: loc()
            )

        case .ident, .entity, .account:
            var name = try readNameWithVariantChain()

            if name == "unit", current == .lPar {
                try expect(.lPar)
                let inner = try readAliasFlexible()
                try expect(.rPar)
                return "unit(\(inner))"
            }

            if current == .lPar {
                try expect(.lPar)
                let inner = try readAliasFlexible()
                try expect(.rPar)

                name.append("#")
                name.append(inner)

                while current == .hash {
                    advance()
                    let variant = try readIdentOrNumberRun(requireAtLeastOne: true)
                    name.append("#")
                    name.append(variant)
                }
            }

            return name

        case .number:
            return try readAliasFlexible()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "segment",
                at: loc()
            )
        }
    }

    // Core: read segmented path (arrow/dot separated)
    @inline(__always)
    func readSegmentsCore(stopAtRPar: Bool) throws -> [String] {
        var segs: [String] = []

        while true {
            if stopAtRPar, current == .rPar {
                break
            }

            switch current {
            case .keyword("inventory"):
                throw ParserError.deprecatedPathSegment(
                    segment: "inventory",
                    suggestion: "objects.storable",
                    at: loc()
                )

            case .ident, .number, .entity, .account:
                segs.append(try readAtomSegment())

            default:
                return segs
            }

            if current == .dot || current == .arrow {
                advance()
                continue
            }

            if !stopAtRPar {
                return segs
            }
        }

        return segs
    }

    // Normalization: unit(x) → merge into previous as "#x"
    // Example: ["objects","usable","vehicle","unit(honda_crv)"] → ["objects","usable","vehicle#honda_crv"]
    @inline(__always)
    func normalizeUnitVariant(_ segs: [String]) -> [String] {
        guard !segs.isEmpty else { return segs }

        var out: [String] = []

        for s in segs {
            if s.hasPrefix("unit("),
               s.hasSuffix(")"),
               let inner = s.split(separator: "(").last?.dropLast(),
               !inner.isEmpty
            {
                if let last = out.popLast() {
                    out.append(last + "#" + inner)
                } else {
                    out.append("unit#" + inner)
                }
            } else {
                out.append(s)
            }
        }

        return out
    }

    @inline(__always)
    func readFlatSegments() -> [String] {
        guard let segs = try? readSegmentsCore(stopAtRPar: false) else {
            return []
        }

        return normalizeUnitVariant(segs)
    }

    func readSegmentsUntilRPar(allowAllAsAlias: Bool = false) throws -> (String, [String]) {
        try expect(.lPar)
        let rawSegs = try readSegmentsCore(stopAtRPar: true)
        try expect(.rPar)

        let segs = normalizeUnitVariant(rawSegs)

        guard !segs.isEmpty else {
            throw ParserError.unexpectedToken(
                current,
                expected: "non-empty path",
                at: loc()
            )
        }

        if allowAllAsAlias {
            return (segs.first ?? "", segs)
        }

        var copy = segs
        let domain = copy.removeFirst()
        return (domain, copy)
    }
}

// public extension EntryCompilerParsing {
//     @inline(__always)
//     func readNameWithVariantChain() throws -> String {
//         guard case let .ident(base0) = current else {
//             throw ParserError.unexpectedToken(current, expected: "identifier", at: loc())
//         }
//         var s = base0
//         advance()

//         while current == .hash {
//             advance() // eat '#'

//             var variant = ""
//             var sawAny = false

//             variantLoop: while true {
//                 switch current {
//                 case let .ident(v):
//                     variant += v
//                     sawAny = true
//                     advance()
//                 case let .number(n):
//                     variant += String(describing: n) // supports Int/Decimal
//                     sawAny = true
//                     advance()
//                 default:
//                     break variantLoop
//                 }
//             }

//             guard sawAny else {
//                 throw ParserError.unexpectedToken(
//                     current, expected: "identifier or number after '#'", at: loc()
//                 )
//             }

//             s.append("#")
//             s.append(variant)
//         }

//         return s
//     }

//     /// Consume a contiguous run of ident/number tokens into a single string.
//     @inline(__always)
//     func readIdentOrNumberRun(requireAtLeastOne: Bool = true) throws -> String {
//         var out = ""
//         var saw = false
//         while true {
//             switch current {
//             case let .ident(s): out += s; saw = true; advance()
//             case let .number(n): out += String(describing: n); saw = true; advance()
//             default: break
//             }
//             // Stop when next isn't ident/number
//             switch current {
//             case .ident, .number: continue
//             default: break
//             }
//             break
//         }
//         if requireAtLeastOne && !saw {
//             throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
//         }
//         return out
//     }

//     /// Like `readNameWithVariantChain` but allows a number as the first token.
//     /// Example: `15_pro_max#rev2`
//     @inline(__always)
//     func readAliasFlexible() throws -> String {
//         var name = try readIdentOrNumberRun(requireAtLeastOne: true)
//         // optional #variant chains
//         while current == .hash {
//             advance()
//             let v = try readIdentOrNumberRun(requireAtLeastOne: true)
//             name.append("#"); name.append(v)
//         }
//         return name
//     }

//     // Atom: ident[#…] | number | unit(<id|number>)
//     // deprecating: use of keyword("inventory") in a segment (ident)
//     // - Accepts: vehicle#honda_crv
//     // - Accepts: unit(honda_crv)  (returned as "unit(honda_crv)" for normalization later)
//     @inline(__always)
//     func readAtomSegment() throws -> String {
//         switch current {
//         // case .keyword("inventory"):
//         //     advance()
//         //     return "inventory"

//         case .keyword("inventory"):
//             throw ParserError.deprecatedPathSegment(
//                 segment: "inventory",
//                 suggestion: "objects.storable",
//                 at: loc()
//             )

//         // case .ident:
//         //     // Try: ident[#...]
//         //     let name = try readNameWithVariantChain()
//         //     // Special-case unit(<id|number>)
//         //     if name == "unit", current == .lPar {
//         //         try expect(.lPar)
//         //         let inner: String
//         //         switch current {
//         //         case .ident:
//         //             inner = try readNameWithVariantChain()
//         //         case let .number(n):
//         //             inner = "\(n)"; advance()
//         //         default:
//         //             throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
//         //         }
//         //         try expect(.rPar)
//         //         return "unit(\(inner))"
//         //     }
//         //     return name

//         // adding compatbility for `macbook#levi(air_m2)`
//         case .ident:
//             // Read base + any "#..." that immediately follow
//             var name = try readNameWithVariantChain()

//             // 1) Existing sugar: unit(<id|number>) → return "unit(<inner>)"
//             //    (later merged into previous segment by normalizeUnitVariant)
//             // if name == "unit", current == .lPar {
//             //     try expect(.lPar)
//             //     let inner: String
//             //     switch current {
//             //     case .ident:
//             //         inner = try readNameWithVariantChain()
//             //     case let .number(n):
//             //         inner = "\(n)"; advance()
//             //     default:
//             //         throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
//             //     }
//             //     try expect(.rPar)
//             //     return "unit(\(inner))"
//             // }
//             if name == "unit", current == .lPar {
//                 try expect(.lPar)
//                 let inner = try readAliasFlexible()
//                 try expect(.rPar)
//                 return "unit(\(inner))"
//             }

//             // 2) NEW sugar: ident[#…](<id|number>) → append as another variant: "#<inner>"
//             //    Example: macbook#levi(air_m2) → "macbook#levi#air_m2"
//             // if current == .lPar {
//             //     try expect(.lPar)
//             //     let inner: String
//             //     switch current {
//             //     case .ident:
//             //         inner = try readNameWithVariantChain()
//             //     case let .number(n):
//             //         inner = "\(n)"; advance()
//             //     default:
//             //         throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
//             //     }
//             //     try expect(.rPar)
//             //     name.append("#")
//             //     name.append(inner)

//             //     // Allow further "#..." AFTER the parens too (e.g., macbook#levi(air_m2)#rev2)
//             //     while current == .hash {
//             //         advance() // eat '#'
//             //         var variant = ""
//             //         var sawAny = false
//             //         while true {
//             //             switch current {
//             //             case let .ident(v): variant += v; sawAny = true; advance()
//             //             case let .number(n): variant += String(describing: n); sawAny = true; advance()
//             //             default: break
//             //             }
//             //             if case .ident = current { continue }
//             //             if case .number = current { continue }
//             //             break
//             //         }
//             //         guard sawAny else {
//             //             throw ParserError.unexpectedToken(current, expected: "identifier or number after '#'", at: loc())
//             //         }
//             //         name.append("#")
//             //         name.append(variant)
//             //     }
//             // }
//             if current == .lPar {
//                 try expect(.lPar)
//                 let inner = try readAliasFlexible()
//                 try expect(.rPar)
//                 name.append("#")
//                 name.append(inner)

//                 // keep your trailing "#…" logic:
//                 while current == .hash {
//                     advance()
//                     let variant = try readIdentOrNumberRun(requireAtLeastOne: true)
//                     name.append("#")
//                     name.append(variant)
//                 }
//             }

//             return name


//         // attempted replacement for `15_pro_max` compatibility
//         // case let .number(n):
//         //     advance()
//         //     return "\(n)"

//         case .number:
//             // attempted glue number-first aliases like `15_pro_max` (and optional #variants)
//             return try readAliasFlexible()

//         default:
//             throw ParserError.unexpectedToken(current, expected: "segment", at: loc())
//         }
//     }

//     // Core: read segmented path (arrow/dot separated)
//     @inline(__always)
//     func readSegmentsCore(stopAtRPar: Bool) throws -> [String] {
//         var segs: [String] = []

//         while true {
//             // Stop for the caller to handle ')'
//             if stopAtRPar, current == .rPar { break }

//             switch current {
//             // case .keyword("inventory"):
//             //     segs.append(try readAtomSegment())

//             case .keyword("inventory"):
//                 throw ParserError.deprecatedPathSegment(
//                     segment: "inventory",
//                     suggestion: "objects.storable",
//                     at: loc()
//                 )

//             case .ident, .number:
//                 segs.append(try readAtomSegment())

//             default:
//                 // Not a segment start → stop
//                 return segs
//             }

//             // Segment separators
//             if current == .dot || current == .arrow {
//                 advance()
//                 continue
//             }

//             // If not stopping inside parens, we’re done when no separator
//             if !stopAtRPar { return segs }
//         }

//         return segs
//     }

//     // Normalization: unit(x) → merge into previous as "#x"
//     // Example: ["objects","usable","vehicle","unit(honda_crv)"] → ["objects","usable","vehicle#honda_crv"]
//     @inline(__always)
//     func normalizeUnitVariant(_ segs: [String]) -> [String] {
//         guard !segs.isEmpty else { return segs }
//         var out: [String] = []
//         for s in segs {
//             if s.hasPrefix("unit("), s.hasSuffix(")"),
//                let inner = s.split(separator: "(").last?.dropLast(), !inner.isEmpty
//             {
//                 if let last = out.popLast() {
//                     out.append(last + "#" + inner)
//                 } else {
//                     // Edge case: unit(...) as first segment — keep as "unit#id"
//                     out.append("unit#" + inner)
//                 }
//             } else {
//                 out.append(s)
//             }
//         }
//         return out
//     }

//     // ---- Public readers (maintaining old API names, now variant + unit aware)
//     /// old: readFlatSegments() → now variant- & unit-aware and normalized.
//     @inline(__always)
//     func readFlatSegments() -> [String] {
//         // Convert throwing core into best-effort (as you had)
//         guard let segs = try? readSegmentsCore(stopAtRPar: false) else { return [] }
//         return normalizeUnitVariant(segs)
//     }

//     /// old: readSegmentsUntilRPar(...) → now variant- & unit-aware and normalized.
//     func readSegmentsUntilRPar(allowAllAsAlias: Bool = false) throws -> (String, [String]) {
//         try expect(.lPar)
//         let rawSegs = try readSegmentsCore(stopAtRPar: true)
//         try expect(.rPar)

//         let segs = normalizeUnitVariant(rawSegs)
//         guard !segs.isEmpty else {
//             throw ParserError.unexpectedToken(current, expected: "non-empty path", at: loc())
//         }

//         if allowAllAsAlias { return (segs.first ?? "", segs) }
//         var copy = segs
//         let domain = copy.removeFirst()
//         return (domain, copy)
//     }
// }

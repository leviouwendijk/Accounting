// import Foundation

// public enum RGSNodeStoreError: Error, CustomStringConvertible, Sendable {
//     case unknownIdentifier(String, at: SourceLocation?)
//     case notPostable(String, at: SourceLocation?)
//     case invalidLevel(expected: ClosedRange<UInt8>, got: UInt8, ident: String, at: SourceLocation?)

//     public var description: String {
//         switch self {
//         case let .unknownIdentifier(ident, loc):
//             return "Unknown RGS identifier '\(ident)'\(loc.describeSuffix)"
//         case let .notPostable(ident, loc):
//             return "RGS identifier '\(ident)' is not postable (abstract in XBRL)\(loc.describeSuffix)"
//         case let .invalidLevel(range, got, ident, loc):
//             return "RGS identifier '\(ident)' is level \(got); expected \(range)\(loc.describeSuffix)"
//         }
//     }
// }

// public struct RGSNodeStore: Sendable {
//     public let chart: CompiledChart
//     private let nodeById: [Int: RGSNode]
//     private let codeByIdentifier: [String: String]

//     public init(chart: CompiledChart) {
//         self.chart = chart
//         var nb: [Int:RGSNode] = [:]
//         for n in chart.nodes { nb[n.id] = n }
//         self.nodeById = nb

//         var map: [String:String] = [:]
//         for (ident, id) in chart.index.byIdentifier {
//             if let node = nb[id] {
//                 map[ident] = node.codes.code
//             }
//         }
//         self.codeByIdentifier = map
//     }

//     /// Resolve ident → posting code, validating postability and level (L4/L5).
//     public func resolveIdentifierToCode(
//         _ ident: String,
//         at loc: SourceLocation?,
//         requirePostable: Bool = true,
//         allowedLevels: ClosedRange<UInt8> = 4...5
//     ) throws -> String {
//         guard let id = chart.index.byIdentifier[ident], let node = nodeById[id] else {
//             throw RGSNodeStoreError.unknownIdentifier(ident, at: loc)
//         }
//         if requirePostable, let xb = node.xbrl, xb.postable == false {
//             throw RGSNodeStoreError.notPostable(ident, at: loc)
//         }
//         if !allowedLevels.contains(node.level) {
//             throw RGSNodeStoreError.invalidLevel(expected: allowedLevels, got: node.level, ident: ident, at: loc)
//         }
//         return node.codes.code
//     }
// }

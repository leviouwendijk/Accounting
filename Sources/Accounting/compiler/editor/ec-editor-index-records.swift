// import Foundation

// public struct ECIndexedEntityDefinition: Sendable, Hashable {
//     public let def: EntityDef
//     public let location: ECDefinitionResult

//     public init(
//         def: EntityDef,
//         location: ECDefinitionResult
//     ) {
//         self.def = def
//         self.location = location
//     }
// }

// public struct ECIndexedAccountDefinition: Sendable, Hashable {
//     public let def: AccountDef
//     public let location: ECDefinitionResult

//     public init(
//         def: AccountDef,
//         location: ECDefinitionResult
//     ) {
//         self.def = def
//         self.location = location
//     }
// }

// public enum ECCompletionKind: String, Sendable, Codable {
//     case entity
//     case account
//     case transaction
//     case keyword
// }

// public struct ECCompletionItem: Sendable, Codable, Hashable {
//     public let label: String
//     public let insertText: String
//     public let detail: String?
//     public let kind: ECCompletionKind

//     public init(
//         label: String,
//         insertText: String? = nil,
//         detail: String? = nil,
//         kind: ECCompletionKind
//     ) {
//         self.label = label
//         self.insertText = insertText ?? label
//         self.detail = detail
//         self.kind = kind
//     }
// }

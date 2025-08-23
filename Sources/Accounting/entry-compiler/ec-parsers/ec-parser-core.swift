import Foundation

// public struct EntryCompilerParserCore: Sendable {
//     internal var tokens: [EntryCompilerToken]
//     internal var index = 0
//     internal var line = 1, column = 1

//     internal var filePath: String?
//     internal var callSiteStack: [InvocationCallSite] = []

//     public init(tokens: [EntryCompilerToken], filePath: String? = nil) {
//         self.tokens = tokens
//         self.filePath = filePath
//     }

//     public var current: EntryCompilerToken { 
//         index < tokens.count ? tokens[index] : .eof 
//     }

//     public mutating func advance() {
//         index += 1; column += 1 
//     }

//     public mutating func expect(_ expected: EntryCompilerToken) throws {
//         guard current == expected else {
//             throw ParserError.unexpectedToken(
//                 current,
//                 expected: "\(expected)",
//                 at: currentLocation()
//             )
//         }
//         advance()
//     }

//     public func currentLocation() -> SourceLocation {
//         SourceLocation(file: filePath, line: line, column: column, invocation: callSiteStack.last)
//     }

//     public mutating func pushCallSite(_ site: InvocationCallSite) {
//         callSiteStack.append(site)
//     }
//     public mutating func popCallSite() {
//         _ = callSiteStack.popLast()
//     }
// }

public struct EntryCompilerParserCore: Sendable {
    internal var tokens: [EntryCompilerToken]
    internal var index = 0

    internal var filePath: String?
    internal var lineMap: [Int]?          // token index -> source line
    internal var callSiteStack: [InvocationCallSite] = []
        
    public var verbose: Bool

    public init(
        tokens: [EntryCompilerToken],
        filePath: String? = nil,
        lineMap: [Int]? = nil,
        verbose: Bool = false
    ) {
        self.tokens = tokens
        self.filePath = filePath
        self.lineMap = lineMap
        self.verbose = verbose
    }

    public var current: EntryCompilerToken {
        index < tokens.count ? tokens[index] : .eof
    }

    public mutating func advance() { index += 1 }

    public mutating func expect(_ expected: EntryCompilerToken) throws {
        guard current == expected else {
            throw ParserError.unexpectedToken(current, expected: "\(expected)", at: currentLocation())
        }
        advance()
    }

    public func currentLocation() -> SourceLocation {
        let line = lineMap.flatMap { map in
            let i = min(index, max(map.count - 1, 0))
            return map.isEmpty ? 1 : map[i]
        } ?? max(index, 1)
        return SourceLocation(file: filePath, line: line, column: 1, invocation: callSiteStack.last)
    }

    public mutating func pushCallSite(_ site: InvocationCallSite) { callSiteStack.append(site) }
    public mutating func popCallSite() { _ = callSiteStack.popLast() }

    @inline(__always)
    public func trace(_ msg: String) {
        guard verbose else { return }
        if let data = ("    \(msg)\n").data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

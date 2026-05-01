import Foundation
import Accounting
import Position

public struct EntryCompilerParserCore: Sendable {
    internal var tokens: [EntryCompilerToken]
    internal var index = 0

    internal var filePath: String?
    internal var lineMap: [Int]?
    internal var spanMap: [PositionSpan]?
    internal var callSiteStack: [InvocationCallSite] = []

    public var verbose: Bool

    public init(
        tokens: [EntryCompilerToken],
        filePath: String? = nil,
        lineMap: [Int]? = nil,
        spanMap: [PositionSpan]? = nil,
        verbose: Bool = false
    ) {
        self.tokens = tokens
        self.filePath = filePath
        self.lineMap = lineMap
        self.spanMap = spanMap
        self.verbose = verbose

        if verbose && filePath == nil {
            if let data = "[warn] parser created without filePath; errors may lack filenames\n".data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
        }
    }

    public var current: EntryCompilerToken {
        index < tokens.count ? tokens[index] : .eof
    }

    public mutating func advance() {
        index += 1
    }

    public mutating func expect(
        _ expected: EntryCompilerToken
    ) throws {
        guard current == expected else {
            throw ParserError.unexpectedToken(
                current,
                expected: "\(expected)",
                at: currentLocation()
            )
        }

        advance()
    }

    public func currentLocation() -> Position {
        if let spanMap {
            let i = min(index, max(spanMap.count - 1, 0))
            // let span = spanMap.isEmpty
            //     ? PositionSpan(
            //         start: Position(line: 1, column: 1),
            //         end: Position(line: 1, column: 1)
            //     )
            //     : spanMap[i]
            let span =
                spanMap.isEmpty
                ? PositionSpan(
                    uncheckedStart: Position(uncheckedFile: nil, line: 1, column: 1),
                    uncheckedEnd: Position(uncheckedFile: nil, line: 1, column: 1)
                )
                : spanMap[i]

            return Position(
                uncheckedFile: filePath ?? span.start.file,
                line: span.start.line,
                column: span.start.column,
                invocation: callSiteStack.last
            )
        }

        let line = lineMap.flatMap { map in
            let i = min(index, max(map.count - 1, 0))
            return map.isEmpty ? 1 : map[i]
        } ?? max(index, 1)

        return Position(
            uncheckedFile: filePath,
            line: line,
            column: 1,
            invocation: callSiteStack.last
        )
    }

    public mutating func pushCallSite(
        _ site: InvocationCallSite
    ) {
        callSiteStack.append(site)
    }

    public mutating func popCallSite() {
        _ = callSiteStack.popLast()
    }

    @inline(__always)
    public func trace(
        _ msg: String
    ) {
        guard verbose else {
            return
        }

        if let data = ("    \(msg)\n").data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

// public struct EntryCompilerParserCore: Sendable {
//     internal var tokens: [EntryCompilerToken]
//     internal var index = 0

//     internal var filePath: String?
//     internal var lineMap: [Int]?          // token index -> source line
//     internal var callSiteStack: [InvocationCallSite] = []
        
//     public var verbose: Bool

//     public init(
//         tokens: [EntryCompilerToken],
//         filePath: String? = nil,
//         lineMap: [Int]? = nil,
//         verbose: Bool = false
//     ) {
//         self.tokens = tokens
//         self.filePath = filePath
//         self.lineMap = lineMap
//         self.verbose = verbose
//         if verbose && filePath == nil {
//             if let data = "[warn] parser created without filePath; errors may lack filenames\n".data(using: .utf8) {
//                 FileHandle.standardError.write(data)
//             }
//         }
//     }

//     public var current: EntryCompilerToken {
//         index < tokens.count ? tokens[index] : .eof
//     }

//     public mutating func advance() { index += 1 }

//     public mutating func expect(_ expected: EntryCompilerToken) throws {
//         guard current == expected else {
//             throw ParserError.unexpectedToken(current, expected: "\(expected)", at: currentLocation())
//         }
//         advance()
//     }

//     public func currentLocation() -> Position {
//         let line = lineMap.flatMap { map in
//             let i = min(index, max(map.count - 1, 0))
//             return map.isEmpty ? 1 : map[i]
//         } ?? max(index, 1)
//         return Position(file: filePath, line: line, column: 1, invocation: callSiteStack.last)
//     }

//     public mutating func pushCallSite(_ site: InvocationCallSite) { callSiteStack.append(site) }
//     public mutating func popCallSite() { _ = callSiteStack.popLast() }

//     @inline(__always)
//     public func trace(_ msg: String) {
//         guard verbose else { return }
//         if let data = ("    \(msg)\n").data(using: .utf8) {
//             FileHandle.standardError.write(data)
//         }
//     }
// }

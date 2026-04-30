import Foundation
import Accounting

private struct ECLSPDocumentState {
    let uri: String
    var text: String
    var version: Int?
    let flavor: EntryCompilerLexingFlavor
    let root: URL?
}

final class ECLSPServer {
    private let transport = LSPTransport()

    private var documents: [String: ECLSPDocumentState] = [:]
    private var workspaceIndexByRootPath: [String: ECWorkspaceIndex] = [:]
    private var initializeRootURI: String?
    private var isShuttingDown = false

    private let semanticTokenLegend: [String] = [
        "keyword",
        "variable",
        "number",
        "string",
        "type",
        "namespace",
        "comment",
        "operator",
        "property",
    ]

    func run() {
        eclspLog("server.run:start")

        while let message = transport.nextMessage() {
            let method = message["method"] as? String ?? "<response>"
            let idText = message["id"].map(String.init(describing:)) ?? "nil"
            eclspLog("server.run:dispatch method=\(method) id=\(idText)")

            handle(message)

            if isShuttingDown {
                eclspLog("server.run:break isShuttingDown=true")
                break
            }
        }

        eclspLog("server.run:end")
    }

    private func handle(
        _ message: [String: Any]
    ) {
        let method = message["method"] as? String
        let id = message["id"]
        let params = message["params"] as? [String: Any] ?? [:]

        eclspLog("server.handle: method=\(method ?? "<nil>") id=\(id.map(String.init(describing:)) ?? "nil")")

        switch method {
        case "initialize":
            initializeRootURI = params["rootUri"] as? String
            eclspLog("server.handle.initialize: rootUri=\(initializeRootURI ?? "nil")")

            if let id {
                eclspLog("server.handle.initialize: before-send")
                transport.send(makeInitializeResponse(id: id))
                eclspLog("server.handle.initialize: after-send")
            }

        case "initialized":
            eclspLog("server.handle.initialized")

        case "shutdown":
            isShuttingDown = true
            eclspLog("server.handle.shutdown")

            if let id {
                transport.send([
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": NSNull()
                ])
            }

        case "exit":
            isShuttingDown = true
            eclspLog("server.handle.exit")

        case "textDocument/didOpen":
            eclspLog("server.handle.didOpen: begin")
            handleDidOpen(params)
            eclspLog("server.handle.didOpen: end")

        case "textDocument/didChange":
            eclspLog("server.handle.didChange: begin")
            handleDidChange(params)
            eclspLog("server.handle.didChange: end")

        case "textDocument/didClose":
            eclspLog("server.handle.didClose: begin")
            handleDidClose(params)
            eclspLog("server.handle.didClose: end")

        case "textDocument/didSave":
            eclspLog("server.handle.didSave: begin")
            handleDidSave(params)
            eclspLog("server.handle.didSave: end")

        case "textDocument/hover":
            eclspLog("server.handle.hover")
            if let id {
                transport.send(makeHoverResponse(id: id, params: params))
            }

        case "textDocument/definition":
            eclspLog("server.handle.definition")
            if let id {
                transport.send(makeDefinitionResponse(id: id, params: params))
            }

        case "textDocument/completion":
            eclspLog("server.handle.completion")
            if let id {
                transport.send(makeCompletionResponse(id: id, params: params))
            }

        case "textDocument/semanticTokens/full":
            eclspLog("server.handle.semanticTokens.full")
            if let id {
                transport.send(makeSemanticTokensResponse(id: id, params: params))
            }

        default:
            eclspLog("server.handle.default method=\(method ?? "<nil>")")
            if let id {
                transport.send([
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": NSNull()
                ])
            }
        }
    }

    private func handleDidOpen(
        _ params: [String: Any]
    ) {
        guard
            let textDocument = params["textDocument"] as? [String: Any],
            let uri = textDocument["uri"] as? String,
            let text = textDocument["text"] as? String
        else {
            eclspLog("server.handleDidOpen: missing textDocument fields")
            return
        }

        let version = textDocument["version"] as? Int
        let flavor = inferFlavor(forDocumentURI: uri)
        let root = eclspResolveProjectRoot(
            forDocumentURI: uri,
            initializeRootURI: initializeRootURI
        )

        eclspLog(
            "server.handleDidOpen: uri=\(uri) version=\(version.map(String.init(describing:)) ?? "nil") flavor=\(String(describing: flavor)) root=\(root?.path ?? "nil") textBytes=\(text.utf8.count)"
        )

        documents[uri] = ECLSPDocumentState(
            uri: uri,
            text: text,
            version: version,
            flavor: flavor,
            root: root
        )

        publishDiagnostics(forURI: uri)
    }

    private func handleDidChange(
        _ params: [String: Any]
    ) {
        guard
            let textDocument = params["textDocument"] as? [String: Any],
            let uri = textDocument["uri"] as? String,
            var state = documents[uri],
            let changes = params["contentChanges"] as? [[String: Any]],
            let last = changes.last,
            let text = last["text"] as? String
        else {
            eclspLog("server.handleDidChange: missing fields")
            return
        }

        state.text = text
        state.version = textDocument["version"] as? Int
        documents[uri] = state

        eclspLog(
            "server.handleDidChange: uri=\(uri) version=\(state.version.map(String.init(describing:)) ?? "nil") textBytes=\(text.utf8.count)"
        )

        publishDiagnostics(forURI: uri)
    }

    private func handleDidClose(
        _ params: [String: Any]
    ) {
        guard
            let textDocument = params["textDocument"] as? [String: Any],
            let uri = textDocument["uri"] as? String
        else {
            eclspLog("server.handleDidClose: missing textDocument.uri")
            return
        }

        eclspLog("server.handleDidClose: uri=\(uri)")
        documents.removeValue(forKey: uri)

        transport.send([
            "jsonrpc": "2.0",
            "method": "textDocument/publishDiagnostics",
            "params": [
                "uri": uri,
                "diagnostics": []
            ]
        ])
    }

    private func handleDidSave(
        _ params: [String: Any]
    ) {
        guard
            let textDocument = params["textDocument"] as? [String: Any],
            let uri = textDocument["uri"] as? String,
            let state = documents[uri],
            let root = state.root
        else {
            eclspLog("server.handleDidSave: missing uri/state/root")
            return
        }

        eclspLog("server.handleDidSave: uri=\(uri) root=\(root.path)")
        workspaceIndexByRootPath.removeValue(forKey: root.path)
        publishDiagnostics(forURI: uri)
    }

    private func makeInitializeResponse(
        id: Any
    ) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "serverInfo": [
                    "name": "eclsp"
                ],
                "capabilities": [
                    "positionEncoding": "utf-16",
                    "textDocumentSync": [
                        "openClose": true,
                        "change": 1,
                        "save": [
                            "includeText": false
                        ]
                    ],
                    "hoverProvider": true,
                    "definitionProvider": true,
                    "completionProvider": [
                        "resolveProvider": false,
                        "triggerCharacters": ["(", ".", " ", "/", "=", "{"],
                    ],
                    "semanticTokensProvider": [
                        "legend": [
                            "tokenTypes": semanticTokenLegend,
                            "tokenModifiers": []
                        ],
                        "full": true
                    ]
                ]
            ]
        ]
    }

    private func makeHoverResponse(
        id: Any,
        params: [String: Any]
    ) -> [String: Any] {
        guard
            let state = stateAndPosition(from: params)
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": NSNull()
            ]
        }

        guard
            let workspace = workspaceIndex(for: state.document),
            let hover = ECEditorService.hover(
                analysis: state.analysis,
                workspace: workspace,
                line: state.line + 1,
                column: state.character + 1
            )
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": NSNull()
            ]
        }

        let text = renderHover(hover)

        return [
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "contents": [
                    "kind": "markdown",
                    "value": text
                ]
            ]
        ]
    }

    private func makeDefinitionResponse(
        id: Any,
        params: [String: Any]
    ) -> [String: Any] {
        guard
            let state = stateAndPosition(from: params)
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": NSNull()
            ]
        }

        guard
            let workspace = workspaceIndex(for: state.document),
            let definition = ECEditorService.definition(
                analysis: state.analysis,
                workspace: workspace,
                line: state.line + 1,
                column: state.character + 1
            )
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": NSNull()
            ]
        }

        let startLine = max(definition.line - 1, 0)
        let startChar = max(definition.column - 1, 0)

        return [
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                [
                    "uri": URL(fileURLWithPath: definition.file).absoluteString,
                    "range": [
                        "start": [
                            "line": startLine,
                            "character": startChar
                        ],
                        "end": [
                            "line": startLine,
                            "character": startChar
                        ]
                    ]
                ]
            ]
        ]
    }

    private func makeCompletionResponse(
        id: Any,
        params: [String: Any]
    ) -> [String: Any] {
        guard
            let state = stateAndPosition(from: params),
            let workspace = workspaceIndex(for: state.document)
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": [
                    "isIncomplete": false,
                    "items": []
                ]
            ]
        }

        if isInLineComment(
            in: state.document.text,
            line: state.line,
            character: state.character
        ) {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": [
                    "isIncomplete": false,
                    "items": []
                ]
            ]
        }

        let allItems = ECEditorService.completions(
            analysis: state.analysis,
            workspace: workspace,
            line: state.line + 1,
            column: state.character + 1,
            documentFilePath: fileURL(from: state.document.uri)?.path
        )

        let accountOnly = !allItems.isEmpty
            && allItems.allSatisfy { $0.kind == .account }

        let searchText = accountOnly
            ? currentAccountSearchText(
                in: state.document.text,
                line: state.line,
                character: state.character
            )
            : currentPrefix(
                in: state.document.text,
                line: state.line,
                character: state.character
            )

        let items = allItems
            .filter { item in
                completionItem(
                    item,
                    matchesSearchText: searchText
                )
            }
            .map { item in
                makeLSPCompletionItem(
                    item,
                    prefix: searchText,
                    line: state.line,
                    character: state.character
                )
            }

        return [
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "isIncomplete": false,
                "items": items
            ]
        ]
    }

    private func makeSemanticTokensResponse(
        id: Any,
        params: [String: Any]
    ) -> [String: Any] {
        guard
            let state = stateAndPosition(from: params)
        else {
            return [
                "jsonrpc": "2.0",
                "id": id,
                "result": [
                    "data": []
                ]
            ]
        }

        let tokens = ECEditorService.semanticTokens(
            source: state.document.text,
            flavor: state.document.flavor
        )

        let data = deltaEncodeSemanticTokens(tokens)

        return [
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "data": data
            ]
        ]
    }

    private func publishDiagnostics(
        forURI uri: String
    ) {
        guard let document = documents[uri] else {
            eclspLog("server.publishDiagnostics: no document for uri=\(uri)")
            return
        }

        eclspLog(
            "server.publishDiagnostics: uri=\(uri) flavor=\(String(describing: document.flavor)) root=\(document.root?.path ?? "nil")"
        )

        let analysis = ECEditorService.analyzeDocument(
            source: document.text,
            flavor: document.flavor
        )

        let workspace = workspaceIndex(for: document)

        let documentFilePath = fileURL(from: uri)?.path

        let mergedDiagnostics = ECEditorService.diagnostics(
            analysis: analysis,
            workspace: workspace,
            documentFilePath: documentFilePath
        )

        eclspLog("server.publishDiagnostics: diagnosticCount=\(mergedDiagnostics.count)")

        let diagnostics = mergedDiagnostics.map { diagnostic in
            let severity: Int = {
                switch diagnostic.severity {
                case .error:
                    return 1

                case .warning:
                    return 2

                case .information:
                    return 3
                }
            }()

            return [
                "range": [
                    "start": [
                        "line": max(diagnostic.span.start.line - 1, 0),
                        "character": max(diagnostic.span.start.column - 1, 0)
                    ],
                    "end": [
                        "line": max(diagnostic.span.end.line - 1, 0),
                        "character": max(diagnostic.span.end.column - 1, 0)
                    ]
                ],
                "severity": severity,
                "source": "eclsp",
                "code": diagnostic.code,
                "message": diagnostic.message
            ]
        }

        transport.send([
            "jsonrpc": "2.0",
            "method": "textDocument/publishDiagnostics",
            "params": [
                "uri": uri,
                "diagnostics": diagnostics
            ]
        ])
    }

    private func workspaceIndex(
        for document: ECLSPDocumentState
    ) -> ECWorkspaceIndex? {
        guard let root = document.root else {
            eclspLog("server.workspaceIndex: no root for uri=\(document.uri)")
            return nil
        }

        if let cached = workspaceIndexByRootPath[root.path] {
            eclspLog("server.workspaceIndex: cache-hit root=\(root.path)")
            return cached
        }

        eclspLog("server.workspaceIndex: building root=\(root.path)")

        guard let built = try? ECWorkspaceIndex.build(projectRoot: root) else {
            eclspLog("server.workspaceIndex: build failed root=\(root.path)")
            return nil
        }

        eclspLog("server.workspaceIndex: build ok root=\(root.path)")
        workspaceIndexByRootPath[root.path] = built
        return built
    }

    private func stateAndPosition(
        from params: [String: Any]
    ) -> (
        document: ECLSPDocumentState,
        analysis: ECDocumentAnalysis,
        line: Int,
        character: Int
    )? {
        guard
            let textDocument = params["textDocument"] as? [String: Any],
            let uri = textDocument["uri"] as? String,
            let position = params["position"] as? [String: Any],
            let line = position["line"] as? Int,
            let character = position["character"] as? Int,
            let document = documents[uri]
        else {
            return nil
        }

        let analysis = ECEditorService.analyzeDocument(
            source: document.text,
            flavor: document.flavor
        )

        return (document, analysis, line, character)
    }

    private func renderHover(
        _ hover: ECHoverResult
    ) -> String {
        var lines: [String] = []
        lines.append("**\(hover.title)**")

        if let subtitle = hover.subtitle, !subtitle.isEmpty {
            lines.append(subtitle)
        }

        if !hover.body.isEmpty {
            lines.append("")
            lines.append(hover.body)
        }

        return lines.joined(separator: "\n")
    }

    private func makeLSPCompletionItem(
        _ item: ECCompletionItem,
        prefix: String,
        line: Int,
        character: Int
    ) -> [String: Any] {
        let kind: Int = {
            if item.insertFormat == .snippet {
                return 15
            }

            switch item.kind {
            case .keyword:
                return 14

            case .entity:
                return 6

            case .account:
                return 6

            case .transaction:
                return 21

            case .value:
                return 12

            case .id:
                return 21

            case .selectGroup:
                return 13
            }
        }()

        let startCharacter = max(character - prefix.count, 0)

        var out: [String: Any] = [
            "label": item.label,
            "kind": kind,
            "insertText": item.insertText,
            "textEdit": [
                "range": [
                    "start": [
                        "line": line,
                        "character": startCharacter
                    ],
                    "end": [
                        "line": line,
                        "character": character
                    ]
                ],
                "newText": item.insertText
            ]
        ]

        if item.insertFormat == .snippet {
            out["insertTextFormat"] = 2
        }

        if let detail = item.detail, !detail.isEmpty {
            out["detail"] = detail
        }

        if let documentation = item.documentation, !documentation.isEmpty {
            out["documentation"] = [
                "kind": "markdown",
                "value": documentation
            ]
        }

        return out
    }

    private func isInLineComment(
        in text: String,
        line: Int,
        character: Int
    ) -> Bool {
        let lines = text.components(separatedBy: "\n")
        guard line >= 0, line < lines.count else {
            return false
        }

        let currentLine = lines[line]
        let chars = Array(currentLine)
        let clamped = min(max(character, 0), chars.count)

        guard clamped >= 2 else {
            return false
        }

        var i = 0
        while i + 1 < clamped {
            if chars[i] == "/", chars[i + 1] == "/" {
                return true
            }

            i += 1
        }

        return false
    }

    private func currentAccountSearchText(
        in text: String,
        line: Int,
        character: Int
    ) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line >= 0, line < lines.count else {
            return ""
        }

        let currentLine = lines[line]
        let chars = Array(currentLine)
        let clamped = min(max(character, 0), chars.count)

        var start = clamped
        while start > 0 {
            let c = chars[start - 1]
            if c.isLetter
                || c.isNumber
                || c == " "
                || c == "_"
                || c == "-"
                || c == "/"
                || c == "."
                || c == "#" {
                start -= 1
            } else {
                break
            }
        }

        return String(chars[start..<clamped])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedCompletionSearchText(
        _ text: String
    ) -> String {
        let lowered = text
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )
            .lowercased()

        var out = ""
        var lastWasSpace = true

        for c in lowered {
            if c.isLetter || c.isNumber {
                out.append(c)
                lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" ")
                lastWasSpace = true
            }
        }

        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func completionItem(
        _ item: ECCompletionItem,
        matchesSearchText searchText: String
    ) -> Bool {
        if searchText.isEmpty {
            return true
        }

        let needle = normalizedCompletionSearchText(searchText)
        if needle.isEmpty {
            return true
        }

        let haystacks = [
            item.label,
            item.insertText,
            item.detail ?? "",
            item.documentation ?? ""
        ]

        for haystack in haystacks {
            let normalizedHaystack = normalizedCompletionSearchText(
                haystack
            )

            if normalizedHaystack.contains(needle) {
                return true
            }
        }

        return false
    }

    private func currentPrefix(
        in text: String,
        line: Int,
        character: Int
    ) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line >= 0, line < lines.count else {
            return ""
        }

        let currentLine = lines[line]
        let chars = Array(currentLine)
        let clamped = min(max(character, 0), chars.count)

        var start = clamped
        while start > 0 {
            let c = chars[start - 1]
            if c.isLetter || c.isNumber || c == "_" || c == "-" || c == "/" || c == "." || c == "#" {
                start -= 1
            } else {
                break
            }
        }

        return String(chars[start..<clamped])
    }

    private func deltaEncodeSemanticTokens(
        _ tokens: [ECSemanticToken]
    ) -> [Int] {
        let sorted = tokens.sorted {
            if $0.line != $1.line {
                return $0.line < $1.line
            }

            if $0.startColumn != $1.startColumn {
                return $0.startColumn < $1.startColumn
            }

            return $0.length < $1.length
        }

        var out: [Int] = []
        out.reserveCapacity(sorted.count * 5)

        var previousLine = 0
        var previousStart = 0

        for token in sorted {
            let tokenType = semanticTokenTypeIndex(token.kind)

            let deltaLine = token.line - previousLine
            let deltaStart: Int
            if deltaLine == 0 {
                deltaStart = token.startColumn - previousStart
            } else {
                deltaStart = token.startColumn
            }

            out.append(deltaLine)
            out.append(deltaStart)
            out.append(token.length)
            out.append(tokenType)
            out.append(0)

            previousLine = token.line
            previousStart = token.startColumn
        }

        return out
    }

    private func semanticTokenTypeIndex(
        _ kind: ECSemanticTokenKind
    ) -> Int {
        let name: String = {
            switch kind {
            case .keyword:
                return "keyword"
            case .variable:
                return "variable"
            case .number:
                return "number"
            case .string:
                return "string"
            case .type:
                return "type"
            case .namespace:
                return "namespace"
            case .comment:
                return "comment"
            case .operatorToken:
                return "operator"
            case .property:
                return "property"
            }
        }()

        return semanticTokenLegend.firstIndex(of: name) ?? 0
    }
}

import Foundation

public enum ECEditorService {
    public static func analyzeDocument(
        source: String,
        flavor: EntryCompilerLexingFlavor
    ) -> ECDocumentAnalysis {
        ECDocumentAnalyzer.analyze(
            source: source,
            flavor: flavor
        )
    }

    public static func semanticTokens(
        source: String,
        flavor: EntryCompilerLexingFlavor
    ) -> [ECSemanticToken] {
        let analysis = analyzeDocument(
            source: source,
            flavor: flavor
        )

        return ECDocumentAnalyzer.semanticTokens(
            from: analysis
        )
    }

    public static func hover(
        analysis: ECDocumentAnalysis,
        workspace: ECWorkspaceIndex,
        line: Int,
        column: Int
    ) -> ECHoverResult? {
        guard let index = analysis.tokenIndex(
            atLine: line,
            column: column
        ) else {
            return nil
        }

        let token = analysis.tokens[index]
        let span = analysis.spans[index]

        switch token {
        case .entity(let raw):
            if let reference = entityReference(
                analysis: analysis,
                at: index
            ) {
                return hoverEntity(
                    reference.ref,
                    raw: reference.raw,
                    at: reference.start,
                    workspace: workspace
                )
            }

            return hoverEntity(
                raw,
                at: span.start,
                workspace: workspace
            )

        case .dot, .hash:
            guard let reference = entityReference(
                analysis: analysis,
                at: index
            ) else {
                return nil
            }

            return hoverEntity(
                reference.ref,
                raw: reference.raw,
                at: reference.start,
                workspace: workspace
            )

        case .account(let raw):
            return hoverAccount(
                raw,
                at: span.start,
                workspace: workspace
            )

        case .number(let decimal):
            if isTransactionReference(
                tokens: analysis.tokens,
                at: index
            ) {
                let id = NSDecimalNumber(decimal: decimal).intValue
                return hoverTransaction(
                    id,
                    at: span.start,
                    workspace: workspace
                )
            }

            return ECHoverResult(
                kind: .token,
                title: "Number",
                body: NSDecimalNumber(decimal: decimal).stringValue
            )

        case .keyword(let s):
            return ECHoverResult(
                kind: .token,
                title: "Keyword",
                body: s
            )

        case .ident(let s):
            return ECHoverResult(
                kind: .token,
                title: "Identifier",
                body: s
            )

        case .dateLiteral(let s):
            return ECHoverResult(
                kind: .token,
                title: "Date",
                body: s
            )

        case .string(let s):
            return ECHoverResult(
                kind: .token,
                title: "String",
                body: s
            )

        default:
            return nil
        }
    }

    public static func definition(
        analysis: ECDocumentAnalysis,
        workspace: ECWorkspaceIndex,
        line: Int,
        column: Int
    ) -> ECDefinitionResult? {
        guard let index = analysis.tokenIndex(
            atLine: line,
            column: column
        ) else {
            return nil
        }

        let token = analysis.tokens[index]
        let span = analysis.spans[index]

        switch token {
        case .entity(let raw):
            if let reference = entityReference(
                analysis: analysis,
                at: index
            ) {
                return definitionEntity(
                    reference.ref,
                    at: reference.start,
                    workspace: workspace
                )
            }

            return definitionEntity(
                raw,
                at: span.start,
                workspace: workspace
            )

        case .dot, .hash:
            guard let reference = entityReference(
                analysis: analysis,
                at: index
            ) else {
                return nil
            }

            return definitionEntity(
                reference.ref,
                at: reference.start,
                workspace: workspace
            )

        case .account(let raw):
            return definitionAccount(
                raw,
                at: span.start,
                workspace: workspace
            )

        case .number(let decimal):
            guard isTransactionReference(
                tokens: analysis.tokens,
                at: index
            ) else {
                return nil
            }

            let id = NSDecimalNumber(decimal: decimal).intValue
            return workspace.transactionDefinitionByID[id]

        default:
            return nil
        }
    }
}

internal extension ECEditorService {
    @inline(__always)
    static func isTransactionReference(
        tokens: [EntryCompilerToken],
        at index: Int
    ) -> Bool {
        guard index > 0 else {
            return false
        }

        switch tokens[index - 1] {
        case .keyword("ref"), .ident("ref"):
            return true

        default:
            return false
        }
    }

    @inline(__always)
    static func isEntityReferenceToken(
        _ token: EntryCompilerToken
    ) -> Bool {
        switch token {
        case .entity,
             .dot,
             .hash:
            return true

        default:
            return false
        }
    }

    static func entityReference(
        analysis: ECDocumentAnalysis,
        at index: Int
    ) -> (
        raw: String,
        ref: EntityRef,
        start: SourceLocation
    )? {
        guard analysis.tokens.indices.contains(index) else {
            return nil
        }

        guard isEntityReferenceToken(analysis.tokens[index]) else {
            return nil
        }

        var lower = index
        while lower > 0,
              isEntityReferenceToken(analysis.tokens[lower - 1]) {
            lower -= 1
        }

        var upper = index
        while upper + 1 < analysis.tokens.count,
              isEntityReferenceToken(analysis.tokens[upper + 1]) {
            upper += 1
        }

        var raw = ""
        var sawEntitySegment = false

        for i in lower...upper {
            switch analysis.tokens[i] {
            case .entity(let s):
                raw += s
                sawEntitySegment = true

            case .dot:
                raw += "."

            case .hash:
                raw += "#"

            default:
                break
            }
        }

        guard sawEntitySegment else {
            return nil
        }

        guard let ref = parseFlexibleEntityRef(raw) else {
            return nil
        }

        return (
            raw: raw,
            ref: ref,
            start: analysis.spans[lower].start
        )
    }

    static func parseFlexibleEntityRef(
        _ raw: String
    ) -> EntityRef? {
        let segments = raw
            .split(separator: ".", omittingEmptySubsequences: false)
            .map(String.init)

        guard !segments.isEmpty else {
            return nil
        }

        guard !segments.contains(where: \.isEmpty) else {
            return nil
        }

        switch segments.count {
        case 1:
            return EntityRef(
                class: nil,
                family: nil,
                alias: EntityAlias.parse(segments[0])
            )

        case 2:
            return EntityRef(
                class: segments[0],
                family: nil,
                alias: EntityAlias.parse(segments[1])
            )

        case 3:
            return EntityRef(
                class: segments[0],
                family: segments[1],
                alias: EntityAlias.parse(segments[2])
            )

        default:
            return nil
        }
    }

    static func hoverEntity(
        _ raw: String,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECHoverResult {
        let ref = parseFlexibleEntityRef(raw)
            ?? EntityRef(
                class: nil,
                family: nil,
                alias: EntityAlias.parse(raw)
            )

        return hoverEntity(
            ref,
            raw: raw,
            at: loc,
            workspace: workspace
        )
    }

    static func hoverEntity(
        _ ref: EntityRef,
        raw: String,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECHoverResult {
        do {
            let resolved = try workspace.entities.resolve(
                ref,
                at: loc
            )

            let title = resolved.key.identifier(
                displaying: .fullchain
            )

            let subtitle: String? = resolved.effectiveDisplayName
            let body = resolved.effectiveDetails
                ?? resolved.effectiveDisplayName
                ?? ""

            return ECHoverResult(
                kind: .entity,
                title: title,
                subtitle: subtitle,
                body: body
            )
        } catch {
            return ECHoverResult(
                kind: .entity,
                title: "Entity",
                subtitle: raw,
                body: String(describing: error)
            )
        }
    }

    static func hoverAccount(
        _ raw: String,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECHoverResult {
        do {
            let resolved: RGSNode

            if let node = try? workspace.accounts.resolve(
                .identifier(raw),
                at: loc
            ) {
                resolved = node
            } else {
                resolved = try workspace.accounts.resolve(
                    .code(raw),
                    at: loc
                )
            }

            let title = resolved.codes.code
            let subtitle = resolved.labels.short
            let directionText = resolved.direction?.rawValue ?? "—"

            let body = [
                "level: \(resolved.level)",
                "direction: \(directionText)",
                "side: \(String(describing: resolved.side))",
            ].joined(separator: "\n")

            return ECHoverResult(
                kind: .account,
                title: title,
                subtitle: subtitle,
                body: body
            )
        } catch {
            return ECHoverResult(
                kind: .account,
                title: "Account",
                subtitle: raw,
                body: String(describing: error)
            )
        }
    }

    static func hoverTransaction(
        _ id: Int,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECHoverResult {
        do {
            let tx = try workspace.transactions.resolve(
                id: id,
                at: loc
            )

            let title = "Transaction \(id)"
            let subtitle = tx.source.rawValue
            let body = [
                "status: \(tx.status.rawValue)",
                "details: \(tx.details ?? "")"
            ].joined(separator: "\n")

            return ECHoverResult(
                kind: .transaction,
                title: title,
                subtitle: subtitle,
                body: body
            )
        } catch {
            return ECHoverResult(
                kind: .transaction,
                title: "Transaction \(id)",
                body: String(describing: error)
            )
        }
    }
}

extension ECEditorService {
    static func definitionEntity(
        _ raw: String,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECDefinitionResult? {
        let ref = parseFlexibleEntityRef(raw)
            ?? EntityRef(
                class: nil,
                family: nil,
                alias: EntityAlias.parse(raw)
            )

        return definitionEntity(
            ref,
            at: loc,
            workspace: workspace
        )
    }

    static func definitionEntity(
        _ ref: EntityRef,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECDefinitionResult? {
        do {
            let resolved = try workspace.entities.resolve(
                ref,
                at: loc
            )

            return workspace.entityDefinitionByKey[resolved.key]
        } catch {
            return nil
        }
    }

    static func definitionAccount(
        _ raw: String,
        at loc: SourceLocation,
        workspace: ECWorkspaceIndex
    ) -> ECDefinitionResult? {
        do {
            if let node = try? workspace.accounts.resolve(
                .identifier(raw),
                at: loc
            ) {
                return workspace.accountDefinitionByIdentifier[raw]
                    ?? workspace.accountDefinitionByCode[node.codes.code]
                    ?? workspace.chartDefinition
            }

            let node = try workspace.accounts.resolve(
                .code(raw),
                at: loc
            )

            return workspace.accountDefinitionByCode[node.codes.code]
                ?? workspace.chartDefinition
        } catch {
            return nil
        }
    }
}

import Foundation

public enum RGSNodeLabelKind: Sendable {
    case short
    case long
}

public enum RGSNodeLabelResolver {
    @inline(__always)
    public static func resolvedLabel(
        for node: RGSNode,
        kind: RGSNodeLabelKind = .short,
        shape: PeriodShape? = nil
    ) -> String {
        resolvedLabelIfNeeded(
            for: node,
            kind: kind,
            shape: shape
        ) ?? baseLabel(
            for: node,
            kind: kind
        )
    }

    @inline(__always)
    public static func resolvedLabelIfNeeded(
        for node: RGSNode,
        kind: RGSNodeLabelKind = .short,
        shape: PeriodShape? = nil
    ) -> String? {
        guard let shape else {
            return nil
        }

        let base = baseLabel(
            for: node,
            kind: kind
        )

        guard requiresBeginBalanceRewrite(
            node: node,
            label: base
        ) else {
            return nil
        }

        guard base.contains("vorig jaar") else {
            return nil
        }

        return base.replacingOccurrences(
            of: "vorig jaar",
            with: shape.kind.previousPeriodLabel
        )
    }

    @inline(__always)
    private static func baseLabel(
        for node: RGSNode,
        kind: RGSNodeLabelKind
    ) -> String {
        switch kind {
        case .short:
            return node.labels.short

        case .long:
            return node.labels.long
        }
    }

    @inline(__always)
    private static func requiresBeginBalanceRewrite(
        node: RGSNode,
        label: String
    ) -> Bool {
        if node.codes.code.hasSuffix("Beg") {
            return true
        }

        return label.localizedCaseInsensitiveContains(
            "beginbalans"
        )
    }
}

public extension RGSNode {
    @inline(__always)
    func presentationLabel(
        _ kind: RGSNodeLabelKind = .short,
        shape: PeriodShape? = nil
    ) -> String {
        RGSNodeLabelResolver.resolvedLabel(
            for: self,
            kind: kind,
            shape: shape
        )
    }

    @inline(__always)
    func presentationLabelIfNeeded(
        _ kind: RGSNodeLabelKind = .short,
        shape: PeriodShape? = nil
    ) -> String? {
        RGSNodeLabelResolver.resolvedLabelIfNeeded(
            for: self,
            kind: kind,
            shape: shape
        )
    }
}

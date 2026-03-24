import Foundation

extension StatementHTMLRenderer {
    static func fmt(_ d: Decimal) -> String {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "nl_NL")
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        return nf.string(from: d as NSDecimalNumber) ?? d.description
    }

    static func nonEmpty(_ s: String?) -> String? {
        guard 
            let t = s?.trimmingCharacters(in: .whitespacesAndNewlines),
            !t.isEmpty
        else { 
            return nil
        }

        return t
    }
}

extension StatementHTMLRenderer {
    @inline(__always)
    static func absDec(_ d: Decimal) -> Decimal { 
        return d < 0 ? -d : d 
    }

    @inline(__always)
    static func levelClass(_ level: Int) -> String {
        return "sr-level-\(min(3, max(0, level)))"
    }

    @inline(__always)
    static func weightClass(_ level: Int) -> String {
        "sr-weight-\(min(3, max(0, level)))"
    }
}

extension StatementHTMLRenderer {
    @inline(__always)
    static func rowLabelClass(
        depth: Int
    ) -> String {
        "sr-label \(levelClass(depth)) \(weightClass(depth))"
    }

    @inline(__always)
    static func rowAmountClass(
        depth: Int
    ) -> String {
        "sr-amount \(weightClass(depth))"
    }

    @inline(__always)
    static func spacingPrefix(
        depth: Int
    ) -> String {
        String(
            repeating: "\u{00a0}\u{00a0}",
            count: max(0, depth)
        )
    }

    @inline(__always)
    static func treePrefix(
        depth: Int,
        hasNextSibling: Bool,
        ancestorHasNextSiblings: [Bool]
    ) -> String {
        guard depth > 0 else {
            return ""
        }

        var out = ""

        for hasNext in ancestorHasNextSiblings {
            out += hasNext ? "│  " : "   "
        }

        out += hasNextSibling ? "├─ " : "└─ "
        return out
    }

    static func hierarchyPrefix(
        depth: Int,
        hasNextSibling: Bool,
        ancestorHasNextSiblings: [Bool],
        options: StatementHTMLRenderer.Options
    ) -> String {
        switch options.hierarchyPrefixStyle {
        case .spacing:
            return spacingPrefix(depth: depth)

        case .tree:
            return treePrefix(
                depth: depth,
                hasNextSibling: hasNextSibling,
                ancestorHasNextSiblings: ancestorHasNextSiblings
            )
        }
    }
}

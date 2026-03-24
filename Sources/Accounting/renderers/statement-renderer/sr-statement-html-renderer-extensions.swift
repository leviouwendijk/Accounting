import Foundation

extension StatementHTMLRenderer {
    @inline(__always)
    static func rowLabelClass(
        indent: Int
    ) -> String {
        "sr-label \(levelClass(indent)) \(weightClass(indent))"
    }

    @inline(__always)
    static func rowAmountClass(
        indent: Int
    ) -> String {
        "sr-amount \(weightClass(indent))"
    }

    @inline(__always)
    static func indentationPrefix(
        _ indent: Int
    ) -> String {
        String(
            repeating: "\u{00a0}\u{00a0}",
            count: max(0, indent)
        )
    }
}

extension StatementHTMLRenderer {
    @inline(__always)
    static func escape(_ s: String) -> String {
        var out = String()
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(ch)
            }
        }
        return out
    }

    // // Formatter + escape identical to before (but used only inside renderer).
    // func escape(_ s: String) -> String {
    //     s.replacingOccurrences(of: "&", with: "&amp;")
    //      .replacingOccurrences(of: "<", with: "&lt;")
    //      .replacingOccurrences(of: ">", with: "&gt;")
    // }

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

    @inline(__always)
    static func hasSiblingAfter(
        index: Int,
        at level: Int,
        in indents: [Int]
    ) -> Bool {
        guard index + 1 < indents.count else {
            return false
        }

        for j in (index + 1)..<indents.count {
            let next = indents[j]

            if next < level {
                return false
            }

            if next == level {
                return true
            }
        }

        return false
    }

    @inline(__always)
    static func treePrefix(
        index: Int,
        indents: [Int]
    ) -> String {
        let level = max(0, indents[index])

        guard level > 0 else {
            return ""
        }

        var out = ""

        if level > 1 {
            for ancestor in 1..<level {
                out += hasSiblingAfter(
                    index: index,
                    at: ancestor,
                    in: indents
                ) ? "│  " : "   "
            }
        }

        out += hasSiblingAfter(
            index: index,
            at: level,
            in: indents
        ) ? "├─ " : "└─ "

        return out
    }

    @inline(__always)
    static func hierarchyPrefix(
        index: Int,
        indent: Int,
        indents: [Int],
        options: StatementHTMLRenderer.Options
    ) -> String {
        switch options.hierarchyPrefixStyle {
        case .spacing:
            return String(
                repeating: "\u{00a0}\u{00a0}",
                count: max(0, indent)
            )

        case .tree:
            return treePrefix(
                index: index,
                indents: indents
            )
        }
    }
}

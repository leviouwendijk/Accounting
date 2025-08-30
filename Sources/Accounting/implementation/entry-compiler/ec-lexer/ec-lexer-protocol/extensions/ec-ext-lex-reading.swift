import Foundation

public extension EntryCompilerLexing {
    mutating func readUntilClosingBraceVerbatim() -> String {
        var depth = 1
        var buffer = ""
        while let c = peek() {
            if c == "{" {
                advance(); depth += 1; buffer.append("{"); continue
            }
            if c == "}" {
                depth -= 1
                if depth == 0 { break }
                advance(); buffer.append("}"); continue
            }
            // IMPORTANT: do not skip whitespace/comments here; just copy raw chars
            buffer.append(Character(c))
            advance()
        }
        return buffer // no trimming
    }

    mutating func skipWhitespaceAndComments() {
        while let c = peek() {
            if CharacterSet.whitespacesAndNewlines.contains(c) {
                advance(); continue
            }
            // single‑line comment `// ...`
            if c == "/" && peek(aheadBy: 1) == "/" {
                advance(); advance() // consume '//'
                while let c2 = peek(), c2 != "\n" { advance() }
                continue
            }
            break
        }
    }

    mutating func readNumber() -> Decimal {
        var buffer = ""
        while let c = peek(), CharacterSet(charactersIn: "0123456789.").contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return Decimal(string: buffer) ?? 0
    }

    mutating func readIdent() -> String {
        var buffer = ""
        // let extra = CharacterSet(charactersIn: "_")
        // let extra = CharacterSet(charactersIn: "_/-")
        let extra = CharacterSet(charactersIn: "_/")
        while let c = peek(), CharacterSet.alphanumerics.union(extra) .contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return buffer
    }

    mutating func readPattern(_ pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: "^\(pattern)")
        let remaining = String(scalars[index...].map { Character($0) })
        let nsrange = NSRange(location: 0, length: remaining.utf16.count)
        if let m = regex.firstMatch(in: remaining, options: [], range: nsrange),
           let range = Range(m.range, in: remaining) {
            let lit = String(remaining[range])
            index += lit.utf16.count  // consume matched chars
            return lit
        }
        throw NSError(domain: "NoPattern", code: 1)
    }

    mutating func readUntilClosingBrace() -> String {
        var depth = 1
        var buffer = ""
        while let c = peek() {
            if c == "{" {
                advance()
                depth += 1
                buffer.append("{")
                continue
            }
            if c == "}" {
                depth -= 1
                if depth == 0 {
                    break
                }
                advance()
                buffer.append("}")
                continue
            }
            advance()
            buffer.append(Character(c))
        }
        return buffer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func readQuotedLiteral() -> String {
        var out = ""
        while let ch = peek() {
            if ch == "\"" { advance(); break }
            if ch == "\\" {
                advance()
                guard let esc = peek() else { break }
                switch esc {
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                case "n":  out.append("\n")
                case "t":  out.append("\t")
                case "r":  out.append("\r")
                default:   out.append(Character(esc))
                }
                advance()
            } else {
                out.append(Character(ch))
                advance()
            }
        }
        return out
    }
}

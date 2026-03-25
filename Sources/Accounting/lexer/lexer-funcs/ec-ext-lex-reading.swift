import Foundation

public enum LexerReadingSets {
    static let digitsDot: CharacterSet = CharacterSet(charactersIn: "0123456789.")
    static let identAllowed: CharacterSet = {
        var s = CharacterSet.alphanumerics
        s.insert(charactersIn: "_/")
        // variations:
        // let extra = CharacterSet(charactersIn: "_")
        // let extra = CharacterSet(charactersIn: "_/-")
        return s
    }()
}

public extension EntryCompilerLexing {
    // optimization implementation
    @inline(__always)
    func isWS(_ c: UnicodeScalar) -> Bool {
        c == " " || c == "\n" || c == "\t" || c == "\r"
    }

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
            // replaced with optimized func
            // if CharacterSet.whitespacesAndNewlines.contains(c) {
            if isWS(c) {
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

    // stop constructing character set on each call
    // retain access to let
    mutating func readNumber() -> Decimal {
        var buffer = ""
        while let c = peek(), LexerReadingSets.digitsDot.contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return Decimal(string: buffer) ?? 0
    }

    mutating func readIdent() -> String {
        var buffer = ""
        while let c = peek(), LexerReadingSets.identAllowed.contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return buffer
    }
    // mutating func readNumber() -> Decimal {
    //     var buffer = ""
    //     while let c = peek(), CharacterSet(charactersIn: "0123456789.").contains(c) {
    //         buffer.append(Character(c))
    //         advance()
    //     }
    //     return Decimal(string: buffer) ?? 0
    // }

    // mutating func readIdent() -> String {
    //     var buffer = ""
    //     // let extra = CharacterSet(charactersIn: "_")
    //     // let extra = CharacterSet(charactersIn: "_/-")
    //     let extra = CharacterSet(charactersIn: "_/")
    //     while let c = peek(), CharacterSet.alphanumerics.union(extra) .contains(c) {
    //         buffer.append(Character(c))
    //         advance()
    //     }
    //     return buffer
    // }

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

    // mutating func readQuotedLiteral() -> String {
    //     var out = ""
    //     while let ch = peek() {
    //         if ch == "\"" { advance(); break }
    //         if ch == "\\" {
    //             advance()
    //             guard let esc = peek() else { break }
    //             switch esc {
    //             case "\"": out.append("\"")
    //             case "\\": out.append("\\")
    //             case "n":  out.append("\n")
    //             case "t":  out.append("\t")
    //             case "r":  out.append("\r")
    //             default:   out.append(Character(esc))
    //             }
    //             advance()
    //         } else {
    //             out.append(Character(ch))
    //             advance()
    //         }
    //     }
    //     return out
    // }

    // replacing with scalarsView for optimized performance
    mutating func readQuotedLiteral() -> String {
        var scalarsOut = String.UnicodeScalarView()
        while let ch = peek() {
            if ch == "\"" { advance(); break }
            if ch == "\\" {
                advance()
                guard let esc = peek() else { break }
                switch esc {
                case "\"": scalarsOut.append("\"".unicodeScalars.first!)
                case "\\": scalarsOut.append("\\".unicodeScalars.first!)
                case "n":  scalarsOut.append(UnicodeScalar(10))  // \n
                case "t":  scalarsOut.append(UnicodeScalar(9))   // \t
                case "r":  scalarsOut.append(UnicodeScalar(13))  // \r
                default:   scalarsOut.append(esc)
                }
                advance()
            } else {
                scalarsOut.append(ch)
                advance()
            }
        }
        return String(scalarsOut)
    }
}

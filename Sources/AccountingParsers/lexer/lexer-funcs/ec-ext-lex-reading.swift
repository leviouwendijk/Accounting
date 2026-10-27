import Foundation

public enum LexerReadingSets {
    static let digitsDot: CharacterSet = CharacterSet(charactersIn: "0123456789.")

    static let identAllowed: CharacterSet = {
        var s = CharacterSet.alphanumerics
        // s.insert(charactersIn: "_/")
        s.insert(charactersIn: "_/-")
        return s
    }()
}

public extension EntryCompilerLexing {
    @inline(__always)
    func isWS(
        _ c: UnicodeScalar
    ) -> Bool {
        CharacterSet.whitespacesAndNewlines.contains(c)
    }

    mutating func readUntilClosingBraceVerbatimResult() -> (text: String, terminated: Bool) {
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
                    return (buffer, true)
                }

                advance()
                buffer.append("}")
                continue
            }

            buffer.append(Character(c))
            advance()
        }

        return (buffer, false)
    }

    mutating func readUntilClosingBraceVerbatim() -> String {
        readUntilClosingBraceVerbatimResult().text
    }

    mutating func skipWhitespaceAndComments() {
        while let c = peek() {
            if isWS(c) {
                advance()
                continue
            }

            if c == "/" && peek(aheadBy: 1) == "/" {
                advance()
                advance()

                while let c2 = peek(), c2 != "\n" {
                    advance()
                }

                continue
            }

            break
        }
    }

    /// Lex decimal digits and an optional fractional part without regexes.
    /// Always consume the entire number-like candidate before reporting invalid input.
    mutating func readNumberResult() -> (raw: String, value: Decimal?) {
        var buffer = ""
        var sawDot = false
        var integerDigits = 0
        var fractionDigits = 0
        var valid = true

        while let c = peek(), c == "." || CharacterSet.decimalDigits.contains(c) {
            buffer.append(Character(c))
            advance()

            if c == "." {
                if sawDot { valid = false }
                sawDot = true
            } else if c.value >= 48 && c.value <= 57 {
                if sawDot { fractionDigits += 1 }
                else { integerDigits += 1 }
            } else {
                // Unicode decimal digits aren't in the .ec numeric grammar.
                valid = false
            }
        }

        guard valid,
              integerDigits > 0,
              (!sawDot || fractionDigits > 0),
              integerDigits + fractionDigits <= 38,
              let value = Decimal(string: buffer, locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN else {
            return (buffer, nil)
        }
        return (buffer, value)
    }

    mutating func readIdent() -> String {
        var buffer = ""

        while let c = peek(), LexerReadingSets.identAllowed.contains(c) {
            buffer.append(Character(c))
            advance()
        }

        return buffer
    }

    mutating func readPattern(_ pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: "^\(pattern)")
        let remaining = String(scalars[index...].map { Character($0) })
        let nsrange = NSRange(location: 0, length: remaining.utf16.count)

        if let match = regex.firstMatch(in: remaining, options: [], range: nsrange),
           let range = Range(match.range, in: remaining) {
            let lit = String(remaining[range])

            for _ in lit.unicodeScalars {
                advance()
            }

            return lit
        }

        throw NSError(domain: "NoPattern", code: 1)
    }

    mutating func readUntilClosingBraceResult() -> (text: String, terminated: Bool) {
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
                    return (
                        buffer.trimmingCharacters(in: .whitespacesAndNewlines),
                        true
                    )
                }

                advance()
                buffer.append("}")
                continue
            }

            advance()
            buffer.append(Character(c))
        }

        return (
            buffer.trimmingCharacters(in: .whitespacesAndNewlines),
            false
        )
    }

    mutating func readUntilClosingBrace() -> String {
        readUntilClosingBraceResult().text
    }

    mutating func readQuotedLiteralResult() -> (text: String, terminated: Bool) {
        var scalarsOut = String.UnicodeScalarView()

        while let ch = peek() {
            if ch == "\"" {
                advance()
                return (String(scalarsOut), true)
            }

            if ch == "\\" {
                advance()

                guard let esc = peek() else {
                    return (String(scalarsOut), false)
                }

                switch esc {
                case "\"":
                    scalarsOut.append("\"".unicodeScalars.first!)
                case "\\":
                    scalarsOut.append("\\".unicodeScalars.first!)
                case "n":
                    scalarsOut.append(UnicodeScalar(10))
                case "t":
                    scalarsOut.append(UnicodeScalar(9))
                case "r":
                    scalarsOut.append(UnicodeScalar(13))
                default:
                    scalarsOut.append(esc)
                }

                advance()
                continue
            }

            scalarsOut.append(ch)
            advance()
        }

        return (String(scalarsOut), false)
    }

    mutating func readQuotedLiteral() -> String {
        readQuotedLiteralResult().text
    }

    mutating func readDigitsRaw() -> String {
        let start = index

        while let c = peek(), CharacterSet.decimalDigits.contains(c) {
            advance()
        }

        return String(String.UnicodeScalarView(scalars[start..<index]))
    }
}

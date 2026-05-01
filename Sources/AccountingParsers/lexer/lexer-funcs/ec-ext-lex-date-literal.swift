import Foundation

public extension EntryCompilerLexing {
    @inline(__always)
    mutating func scanDateLiteral() -> String? {
        @inline(__always)
        func isDigit(_ u: UnicodeScalar?) -> Bool {
            guard let v = u?.value else {
                return false
            }

            return v >= 48 && v <= 57
        }

        @inline(__always)
        func isSep(_ u: UnicodeScalar?) -> Bool {
            u == "-" || u == "/" || u == "."
        }

        let startIdx = index
        let startLine = line
        let startColumn = column
        let startLastConsumedLine = lastConsumedLine
        let startLastConsumedColumn = lastConsumedColumn

        var buf = ""

        func restore() {
            index = startIdx
            line = startLine
            column = startColumn
            lastConsumedLine = startLastConsumedLine
            lastConsumedColumn = startLastConsumedColumn
        }

        func readDigits(_ n: Int) -> Bool {
            for _ in 0..<n {
                guard let c = peek(), isDigit(c) else {
                    return false
                }

                buf.unicodeScalars.append(c)
                advance()
            }

            return true
        }

        func readSep() -> Bool {
            guard let c = peek(), isSep(c) else {
                return false
            }

            buf.unicodeScalars.append(c)
            advance()
            return true
        }

        if readDigits(4), readSep(), readDigits(2), readSep(), readDigits(2) {
            return buf
        }

        restore()
        buf.removeAll(keepingCapacity: true)

        if readDigits(2), readSep(), readDigits(2), readSep(), readDigits(4) {
            return buf
        }

        restore()
        return nil
    }
}

import Foundation

public extension EntryCompilerLexing {
    @inline(__always)
    mutating func scanDateLiteral() -> String? {
        // Accept: YYYY[-/.]MM[-/.]DD  OR  DD[-/.]MM[-/.]YYYY
        @inline(__always) func isDigit(_ u: UnicodeScalar?) -> Bool {
            guard let v = u?.value else { return false }; return v >= 48 && v <= 57
        }
        @inline(__always) func isSep(_ u: UnicodeScalar?) -> Bool {
            return u == "-" || u == "/" || u == "."
        }

        let startIdx = index
        var buf = ""

        func readDigits(_ n: Int) -> Bool {
            for _ in 0..<n {
                guard let c = peek(), isDigit(c) else { return false }
                buf.unicodeScalars.append(c); advance()
            }
            return true
        }
        func readSep() -> Bool {
            guard let c = peek(), isSep(c) else { return false }
            buf.unicodeScalars.append(c); advance(); return true
        }

        // Try YYYY-sep-MM-sep-DD
        if readDigits(4), readSep(), readDigits(2), readSep(), readDigits(2) {
            return buf
        }

        // Reset and try DD-sep-MM-sep-YYYY
        index = startIdx
        // keep line/column consistent (digits/sep aren’t newlines)
        // If you track column separately, you can restore it here if needed.

        buf.removeAll(keepingCapacity: true)
        if readDigits(2), readSep(), readDigits(2), readSep(), readDigits(4) {
            return buf
        }

        // No match
        index = startIdx
        return nil
    }
}

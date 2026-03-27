import Foundation

// public extension EntryCompilerLexing {
//     @inline(__always) func peek(aheadBy n: Int = 0) -> UnicodeScalar? {
//         let i = index + n
//         return i < scalars.count ? scalars[i] : nil
//     }

//     @inline(__always) mutating func advance() {
//         if index < scalars.count {
//             let c = scalars[index]
//             index += 1
//             if c == "\n" { line += 1; column = 1 } else { column += 1 }
//         } else {
//             index += 1
//         }
//     }
// }

public extension EntryCompilerLexing {
    @inline(__always)
    func peek(aheadBy n: Int = 0) -> UnicodeScalar? {
        let i = index + n
        return i < scalars.count ? scalars[i] : nil
    }

    @inline(__always)
    mutating func advance() {
        if index < scalars.count {
            let c = scalars[index]

            lastConsumedLine = line
            lastConsumedColumn = column

            index += 1

            if c == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
        } else {
            index += 1
        }
    }
}

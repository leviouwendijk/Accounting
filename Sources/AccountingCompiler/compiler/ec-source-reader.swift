import Foundation
import Readers

/// All .ec source files require exact UTF-8; preserve source newlines for token positions.
func readECSource(at url: URL) throws -> String {
    try TextFileReader(url).read(
        options: .init(
            decoding: .utf8,
            missingFilePolicy: .throwError,
            newlineNormalization: .preserve
        )
    ).text
}

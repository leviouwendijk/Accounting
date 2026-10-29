import Foundation
import Path

/// Validated, canonical entry path construction. Legacy `makeEntryPath` remains
/// source-compatible, including its optional zero-padded-month behavior.
public func makeValidatedEntryPath(
    root: URL,
    period: EntrySourcePeriod,
    filenameStem: String,
    archived: Bool = false
) throws -> URL {
    let relative = try EntrySourcePath.render(
        period: period,
        filenameStem: filenameStem,
        archived: archived
    )
    return relative.url(base: root, filetype: false)
}

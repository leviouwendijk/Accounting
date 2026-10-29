import Foundation
import Path

/// The path format is independent of the filesystem root and its authorization.
/// A filename is supplied as the *stem*; the .ec extension belongs to the layout.
public enum EntrySourcePath {
    public static let year = PathField<Int>("year")
    public static let quarter = PathField<Int>("quarter")
    public static let month = PathField<Int>("month")
    public static let filename = PathField<String>("filename")

    /// Shared period/terminal-file fragment for live and archived entries.
    public static let periodFile = PathLayout(
        .capture(year),
        .capture(quarter),
        .capture(month),
        .file(stem: filename, extension: "ec")
    )

    public static let live = PathLayout(
        .literal("entries"),
        .include(periodFile)
    )

    public static let trash = PathLayout(
        .literal("archive"),
        .literal("trash"),
        .include(periodFile)
    )

    public static func period(
        from path: StandardPath,
        alignment: PathLayoutAlignment = .suffix
    ) throws -> EntrySourcePeriod {
        let match: PathLayoutMatch
        do {
            match = try periodFile.decode(path, alignment: alignment)
        } catch PathLayoutError.invalidCapture(let name, let value) {
            switch name {
            case year.name: throw EntryDateInferenceError.badYear(value)
            case quarter.name: throw EntryDateInferenceError.badQuarter(value)
            case month.name: throw EntryDateInferenceError.badMonth(value)
            default: throw EntryDateInferenceError.badPath(value)
            }
        } catch {
            throw EntryDateInferenceError.badPath(
                path.segments.map(\.value).joined(separator: "/")
            )
        }

        return try EntrySourcePeriod(
            year: match.value(for: year),
            quarter: match.value(for: quarter),
            month: match.value(for: month)
        )
    }

    public static func render(
        period: EntrySourcePeriod,
        filenameStem: String,
        archived: Bool = false
    ) throws -> StandardPath {
        var values = PathLayoutValues()
        values.set(period.year, for: year)
        values.set(period.quarter, for: quarter)
        values.set(period.month, for: month)
        values.set(filenameStem, for: filename)
        return try (archived ? trash : live).render(values)
    }
}

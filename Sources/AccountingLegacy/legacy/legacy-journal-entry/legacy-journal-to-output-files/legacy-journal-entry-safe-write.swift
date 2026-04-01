import Foundation
import Accounting
import Writers

public struct MonthlyWriteResult: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let yqm: YQM
    public let type: LegacyJournalEntryType
    public let relativePath: String
    public let url: URL
    public let count: Int
    public let bytesWritten: Int
    public let safeWriteResult: SafeWriteResult

    public var description: String {
        let p = url.path
        return "\(yqm.year)/Q\(yqm.quarter)/\(String(format: "%02d", yqm.month)) \(type.convertForEC()).ec → \(count) entries (\(bytesWritten) bytes) @ \(p)"
    }

    public var debugDescription: String {
        let collatedDescs: [String] = [
            self.description,
            self.safeWriteResult.description,
            self.safeWriteResult.debugDescription,
            "\n"
        ]
        let out = collatedDescs.joined(separator: "\n")
        return out
    }
}

public extension Array where Element == LegacyJournalEntry {
    @discardableResult
    func writeMonthlyTypeECFiles(
        root: URL,
        padMonth: Bool = false,
        tz: TimeZone = .current,
        fileHeader: ((YQM, LegacyJournalEntryType, [LegacyJournalEntry]) -> String)? = nil,
        writeOptions: SafeWriteOptions = .init(),
        translation: [LegacyMap]? = nil,
        overrides: [LegacyMapOverrideExceptions] = LegacyTranslation.rgs_v3_8_overrides,
        idProvider: ((LegacyJournalEntry) -> Int)? = nil
    ) throws -> [MonthlyWriteResult] {
        precondition(root.isFileURL, "Output root must be a file URL")

        LegacyTranslation.assertUniqueLegacyOverrides(
            overrides,
            fatal: false
        )

        // 1) Group by month-bucket + type
        let buckets = try groupedByYQMAndType(tz: tz)

        var results: [MonthlyWriteResult] = []
        results.reserveCapacity(buckets.count * 2)

        // 2) Emit files
        for (bucket, byType) in buckets {
            let monthDir = padMonth ? String(format: "%02d", bucket.month) : String(bucket.month)

            for (t, entries) in byType {
                // path e.g. "<root>/2023/4/12/regular.ec"
                let relative = "\(bucket.year)/\(bucket.quarter)/\(monthDir)/\(t.convertForEC()).ec"
                let fileURL = root
                    .appendingPathComponent(String(bucket.year), isDirectory: true)
                    .appendingPathComponent(String(bucket.quarter), isDirectory: true)
                    .appendingPathComponent(monthDir, isDirectory: true)
                    .appendingPathComponent(t.convertForEC())
                    .appendingPathExtension("ec")

                // ensure parent dir exists
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                // optional header
                var pieces: [String] = []
                if let header = fileHeader {
                    pieces.append(header(bucket, t, entries))
                }

                // after (convert maps → dict, with default)
                let mapDict: [Int: LegacyMap] = (translation ?? LegacyTranslation.rgs_v3_8).byLegacyID

                let body = entries
                    .sorted { $0.id < $1.id }
                    .map { e in e.ecString(using: mapDict, overrides: overrides, idOverride: idProvider?(e)) }
                    .joined(separator: "\n\n")

                pieces.append(body)
                let text = pieces.joined(separator: pieces.count > 1 ? "\n\n" : "")

                // try text.write(to: fileURL, atomically: true, encoding: .utf8)
                // above replaced with SafeFile writing:
                let sf = SafeFile(fileURL)
                let writeResult = try sf.write(text, options: writeOptions)

                // result
                let bytes = text.lengthOfBytes(using: .utf8)
                results.append(
                    .init(
                        yqm: bucket,
                        type: t,
                        relativePath: relative,
                        url: fileURL,
                        count: entries.count,
                        bytesWritten: bytes,
                        safeWriteResult: writeResult
                    )
                )
            }
        }

        // stable order for return value
        results.sort {
            ($0.yqm.year, $0.yqm.quarter, $0.yqm.month, $0.type.convertForEC())
            <
            ($1.yqm.year, $1.yqm.quarter, $1.yqm.month, $1.type.convertForEC())
        }
        return results
    }
}

import Foundation

extension TaxonomyProber {
    public static func listZIPEntries(
        zipFileURL: URL
    ) throws -> [String] {
        let unzip = try unzipPath()
        let output = try runCommand(
            unzip,
            ["-Z1", zipFileURL.path]
        )

        return output
            .components(separatedBy: .newlines)
            .map(trim)
            .filter { !$0.isEmpty }
    }

    public static func readZIPEntryText(
        zipFileURL: URL,
        entryPath: String
    ) throws -> String {
        let unzip = try unzipPath()
        let output = try runCommand(
            unzip,
            ["-p", zipFileURL.path, entryPath]
        )

        return output
    }

    public static func resolveZIPEntryPath(
        _ href: String,
        relativeTo baseEntryPath: String
    ) -> String {
        if href.isEmpty {
            return href
        }

        if href.hasPrefix("/") {
            return String(href.dropFirst())
        }

        let hrefWithoutFragment = href.components(separatedBy: "#").first ?? href
        let baseURL = URL(fileURLWithPath: "/" + baseEntryPath)
        let resolvedURL = URL(
            fileURLWithPath: hrefWithoutFragment,
            relativeTo: baseURL.deletingLastPathComponent()
        ).standardizedFileURL

        return String(resolvedURL.path.dropFirst())
    }
}

public func listZIPEntries(
    zipFileURL: URL
) throws -> [String] {
    try TaxonomyProber.listZIPEntries(zipFileURL: zipFileURL)
}

public func readZIPEntryText(
    zipFileURL: URL,
    entryPath: String
) throws -> String {
    try TaxonomyProber.readZIPEntryText(
        zipFileURL: zipFileURL,
        entryPath: entryPath
    )
}

public func resolveZIPEntryPath(
    _ href: String,
    relativeTo baseEntryPath: String
) -> String {
    TaxonomyProber.resolveZIPEntryPath(
        href,
        relativeTo: baseEntryPath
    )
}

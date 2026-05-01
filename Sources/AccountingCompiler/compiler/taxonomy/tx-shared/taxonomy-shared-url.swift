import Accounting
import Foundation

extension TaxonomyShared {
    public static func urlFromStringOrPath(
        _ value: String
    ) throws -> URL {
        if let url = URL(string: value), url.scheme != nil {
            return url
        }

        let expanded: String
        if value.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            expanded = home + String(value.dropFirst())
        } else {
            expanded = value
        }

        let url = URL(fileURLWithPath: expanded)

        guard !expanded.isEmpty else {
            throw TaxonomyProbeError.invalidURL(value)
        }

        return url
    }

    public static func resolveURL(
        _ href: String,
        relativeTo baseURL: URL
    ) -> URL? {
        if let absolute = URL(string: href), absolute.scheme != nil {
            return absolute
        }

        return URL(string: href, relativeTo: baseURL)?.absoluteURL
    }
}

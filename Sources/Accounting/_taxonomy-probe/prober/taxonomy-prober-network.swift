import Foundation

extension TaxonomyProber {
    public static func fetchData(
        from url: URL
    ) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw TaxonomyProbeError.network(error.localizedDescription)
        }
    }

    public static func fetchText(
        from url: URL
    ) throws -> String {
        let data = try fetchData(from: url)

        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }

        if let utf16 = String(data: data, encoding: .utf16) {
            return utf16
        }

        if let isoLatin1 = String(data: data, encoding: .isoLatin1) {
            return isoLatin1
        }

        throw TaxonomyProbeError.network(
            "Unable to decode text response from \(url.absoluteString)"
        )
    }
}

public func fetchData(
    from url: URL
) throws -> Data {
    try TaxonomyProber.fetchData(from: url)
}

public func fetchText(
    from url: URL
) throws -> String {
    try TaxonomyProber.fetchText(from: url)
}

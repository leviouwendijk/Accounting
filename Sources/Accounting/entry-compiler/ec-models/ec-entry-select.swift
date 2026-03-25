import Foundation

public struct EntrySelect: Hashable, Codable, Sendable {
    public var groups: [String]

    public init(
        groups: [String] = []
    ) {
        self.groups = groups
    }

    public var isEmpty: Bool {
        groups.isEmpty
    }
}

public extension EntrySelect {
    @inline(__always)
    static func normalizeGroup(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    @inline(__always)
    static func normalizedUniqueGroups(
        _ rawValues: [String]
    ) -> [String] {
        var out: [String] = []
        var seen = Set<String>()

        for raw in rawValues {
            let value = normalizeGroup(raw)
            guard !value.isEmpty else {
                continue
            }

            if seen.insert(value).inserted {
                out.append(value)
            }
        }

        return out
    }
}

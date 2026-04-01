import Foundation

public enum ECSourceSelection {
    public static func uniqueFiles(
        _ files: [ECSourceFile]
    ) -> [ECSourceFile] {
        var seen = Set<String>()
        var out: [ECSourceFile] = []

        for file in files.sorted(by: { $0.relativePath < $1.relativePath }) {
            if seen.insert(file.absolutePath).inserted {
                out.append(file)
            }
        }

        return out
    }

    public static func parseIntegerSelection(
        _ rawValues: [String],
        argumentName: String
    ) throws -> [Int] {
        var out: [Int] = []
        var seen = Set<Int>()

        for raw in rawValues {
            let parts = splitCSVLikeSelection(raw)

            for part in parts {
                guard let value = Int(part) else {
                    throw NSError(
                        domain: "ECSourceSelection",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Invalid \(argumentName) value '\(part)'. Use integer values, optionally comma-separated."
                        ]
                    )
                }

                if seen.insert(value).inserted {
                    out.append(value)
                }
            }
        }

        return out.sorted()
    }

    public static func parseNormalizedGroupSelection(
        _ rawValues: [String]
    ) -> [String] {
        var out: [String] = []
        var seen = Set<String>()

        for raw in rawValues {
            let parts = splitCSVLikeSelection(raw)

            for part in parts {
                let value = EntrySelect.normalizeGroup(part)

                guard !value.isEmpty else {
                    continue
                }

                if seen.insert(value).inserted {
                    out.append(value)
                }
            }
        }

        return out.sorted()
    }

    public static func collectFiles(
        root: URL,
        scopeURLs: [URL],
        explicitPaths: [String]
    ) throws -> [ECSourceFile] {
        var files: [ECSourceFile] = []

        if !explicitPaths.isEmpty {
            for raw in explicitPaths {
                let pathURL = resolvePath(
                    raw,
                    relativeTo: root
                )

                files.append(
                    contentsOf: try ECSourceProjectReader.read(
                        at: pathURL,
                        relativeTo: root
                    )
                )
            }

            return uniqueFiles(files)
        }

        for url in scopeURLs {
            files.append(
                contentsOf: try ECSourceProjectReader.read(
                    at: url,
                    relativeTo: root
                )
            )
        }

        return uniqueFiles(files)
    }

    public static func filterFiles(
        _ files: [ECSourceFile],
        matchingEntryIDs ids: Set<Int>
    ) -> [ECSourceFile] {
        guard !ids.isEmpty else {
            return files
        }

        return files.compactMap { file in
            let filteredBlocks = file.blocks.filter { block in
                guard block.kind == .entry else {
                    return false
                }

                guard let id = block.summary?.id else {
                    return false
                }

                return ids.contains(id)
            }

            guard !filteredBlocks.isEmpty else {
                return nil
            }

            return file.replacingBlocks(filteredBlocks)
        }
    }

    public static func filterFiles(
        _ files: [ECSourceFile],
        matchingGroups groups: Set<String>
    ) -> [ECSourceFile] {
        guard !groups.isEmpty else {
            return files
        }

        return files.compactMap { file in
            let filteredBlocks = file.blocks.filter { block in
                let normalized = Set(
                    (block.summary?.groups ?? []).map(EntrySelect.normalizeGroup)
                )

                return !normalized.isDisjoint(with: groups)
            }

            guard !filteredBlocks.isEmpty else {
                return nil
            }

            return file.replacingBlocks(filteredBlocks)
        }
    }

    public static func selectionLabel(
        scopeLabel: String,
        explicitPaths: [String],
        ids: [Int],
        groups: [String]
    ) -> String {
        var parts: [String] = []

        if explicitPaths.isEmpty {
            parts.append(scopeLabel)
        } else {
            parts.append(explicitPaths.joined(separator: ", "))
        }

        if !ids.isEmpty {
            parts.append(
                "ids: \(ids.map(String.init).joined(separator: ", "))"
            )
        }

        if !groups.isEmpty {
            parts.append(
                "groups: \(groups.joined(separator: ", "))"
            )
        }

        return parts.joined(separator: " · ")
    }

    public static func outputBaseName(
        scopeLabel: String,
        explicitPaths: [String],
        ids: [Int],
        groups: [String]
    ) -> String {
        let idSuffix: String = {
            guard !ids.isEmpty else {
                return ""
            }

            if ids.count <= 6 {
                return "-ids-" + ids.map(String.init).joined(separator: "-")
            }

            return "-ids-\(ids.count)-selection"
        }()

        let groupSuffix: String = {
            guard !groups.isEmpty else {
                return ""
            }

            if groups.count == 1 {
                return "-group-" + groups[0]
            }

            if groups.count <= 4 {
                return "-groups-" + groups.joined(separator: "-")
            }

            return "-groups-\(groups.count)-selection"
        }()

        if explicitPaths.count == 1 {
            let raw = explicitPaths[0]
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ".ec", with: "")
            return "source-\(raw)\(idSuffix)\(groupSuffix)"
        }

        if !explicitPaths.isEmpty {
            return "source-selection\(idSuffix)\(groupSuffix)"
        }

        return "source-\(scopeLabel)\(idSuffix)\(groupSuffix)"
    }

    private static func resolvePath(
        _ raw: String,
        relativeTo root: URL
    ) -> URL {
        let url = URL(fileURLWithPath: raw)

        if url.path.hasPrefix("/") {
            return url.standardizedFileURL
        }

        return root
            .appendingPathComponent(raw)
            .standardizedFileURL
    }

    private static func splitCSVLikeSelection(
        _ raw: String
    ) -> [String] {
        raw.split(
            separator: ",",
            omittingEmptySubsequences: false
        )
        .map(String.init)
        .map {
            $0.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
        .filter { !$0.isEmpty }
    }
}

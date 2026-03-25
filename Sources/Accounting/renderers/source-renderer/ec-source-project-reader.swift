import Foundation

public enum ECSourceProjectReader {
    public static func read(
        at url: URL,
        relativeTo root: URL? = nil
    ) throws -> [ECSourceFile] {
        let fm = FileManager.default
        let rootURL = (root ?? url).standardizedFileURL
        let targetURL = url.standardizedFileURL

        var fileURLs: [URL] = []
        var seenPaths = Set<String>()

        var isDirectory: ObjCBool = false
        if fm.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                if let enumerator = fm.enumerator(
                    at: targetURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) {
                    for case let rawFileURL as URL in enumerator {
                        let fileURL = rawFileURL.standardizedFileURL

                        guard fileURL.pathExtension.lowercased() == "ec" else {
                            continue
                        }

                        guard seenPaths.insert(fileURL.path).inserted else {
                            continue
                        }

                        fileURLs.append(fileURL)
                    }
                }
            } else if targetURL.pathExtension.lowercased() == "ec" {
                if seenPaths.insert(targetURL.path).inserted {
                    fileURLs.append(targetURL)
                }
            }
        }

        fileURLs.sort { $0.path < $1.path }

        return try fileURLs.map { fileURL in
            let raw = try String(
                contentsOf: fileURL,
                encoding: .utf8
            )

            let normalized = raw
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")

            let relativePath = relativePathOf(
                fileURL,
                from: rootURL
            )

            return ECSourceFile(
                relativePath: relativePath,
                absolutePath: fileURL.path,
                blocks: ECSourceBlockExtractor.extract(from: normalized)
            )
        }
    }

    private static func relativePathOf(
        _ fileURL: URL,
        from rootURL: URL
    ) -> String {
        let filePath = fileURL.standardizedFileURL.path
        let rootPath = rootURL.standardizedFileURL.path

        if filePath.hasPrefix(rootPath + "/") {
            return String(filePath.dropFirst(rootPath.count + 1))
        }

        if filePath == rootPath {
            return fileURL.lastPathComponent
        }

        return fileURL.path
    }
}

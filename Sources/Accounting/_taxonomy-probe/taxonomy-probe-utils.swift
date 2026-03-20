import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension TaxonomyProbe {
    static func stderrPrint(_ message: String) {
        let data = Data((message + "\n").utf8)
        FileHandle.standardError.write(data)
    }

    static func localName(_ name: String?) -> String {
        guard let name else {
            return ""
        }

        if let idx = name.lastIndex(of: ":") {
            return String(name[name.index(after: idx)...])
        }

        return name
    }

    static func attributeValue(_ attributes: [String: String], _ names: [String]) -> String? {
        for name in names {
            if let value = attributes[name] {
                return value
            }
        }

        for (key, value) in attributes {
            let keyLocal = localName(key)
            if names.contains(where: { localName($0) == keyLocal }) {
                return value
            }
        }

        return nil
    }

    static func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    static func resolveURL(_ href: String, relativeTo base: URL) throws -> URL {
        if let absolute = URL(string: href), absolute.scheme != nil {
            return absolute
        }

        guard let resolved = URL(string: href, relativeTo: base)?.absoluteURL else {
            throw Error.invalidURL("href=\(href) relativeTo=\(base.absoluteString)")
        }

        return resolved
    }

    static func conceptName(from locatorHref: String) -> String {
        if let url = URL(string: locatorHref), let fragment = url.fragment, !fragment.isEmpty {
            return fragment
        }

        if let hashIndex = locatorHref.lastIndex(of: "#") {
            let next = locatorHref.index(after: hashIndex)
            return String(locatorHref[next...])
        }

        return locatorHref
    }

    static func fetchData(from url: URL) throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var capturedData: Data?
        var capturedResponse: URLResponse?
        var capturedError: Swift.Error?

        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 60
        )

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            capturedData = data
            capturedResponse = response
            capturedError = error
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        if let capturedError {
            throw Error.network(capturedError.localizedDescription)
        }

        if let http = capturedResponse as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw Error.http(http.statusCode, url.absoluteString)
        }

        guard let capturedData else {
            throw Error.network("no data returned for \(url.absoluteString)")
        }

        return capturedData
    }

    static func fetchText(from url: URL) throws -> String {
        let data = try fetchData(from: url)

        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }

        throw Error.parseFailed("could not decode text from \(url.absoluteString)")
    }

    static func urlFromStringOrPath(_ value: String) throws -> URL {
        if let url = URL(string: value), url.scheme != nil {
            return url
        }

        if value.hasPrefix("/") {
            return URL(fileURLWithPath: value)
        }

        throw Error.invalidURL(value)
    }

    static func writeTempFile(data: Data, suffix: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(suffix)

        do {
            try data.write(to: tempURL)
        } catch {
            throw Error.unableToWriteTempFile
        }

        return tempURL
    }

    static func runCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
        let fileManager = FileManager.default

        let stdoutURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("stdout")

        let stderrURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("stderr")

        _ = fileManager.createFile(atPath: stdoutURL.path, contents: Data())
        _ = fileManager.createFile(atPath: stderrURL.path, contents: Data())

        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)

        defer {
            stdoutHandle.closeFile()
            stderrHandle.closeFile()
            try? fileManager.removeItem(at: stdoutURL)
            try? fileManager.removeItem(at: stderrURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = stdoutHandle
        process.standardError = stderrHandle

        try process.run()
        process.waitUntilExit()

        let stdoutData = try Data(contentsOf: stdoutURL)
        let stderrData = try Data(contentsOf: stderrURL)

        let stdout = String(data: stdoutData, encoding: .utf8)
            ?? String(decoding: stdoutData, as: UTF8.self)

        let stderr = String(data: stderrData, encoding: .utf8)
            ?? String(decoding: stderrData, as: UTF8.self)

        guard process.terminationStatus == 0 else {
            throw Error.commandFailed(
                "\(launchPath) \(arguments.joined(separator: " "))\n\(stderr)"
            )
        }

        return stdout
    }

    static func unzipPath() throws -> String {
        let candidates = [
            "/usr/bin/unzip",
            "/bin/unzip"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        throw Error.commandUnavailable("Could not find an executable unzip binary")
    }
}

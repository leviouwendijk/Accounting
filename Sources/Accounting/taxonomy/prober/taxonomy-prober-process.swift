import Foundation

extension TaxonomyProber {
    public static func runCommand(
        _ launchPath: String,
        _ arguments: [String]
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()

        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw TaxonomyProbeError.commandUnavailable(launchPath)
        }

        process.waitUntilExit()

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()

        let stdoutText = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let message = stderrText.isEmpty ? stdoutText : stderrText
            throw TaxonomyProbeError.commandFailed(trim(message))
        }

        return stdoutText
    }

    public static func writeTempFile(
        data: Data,
        suffix: String
    ) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let fileURL = directory.appendingPathComponent(
            UUID().uuidString + "." + suffix
        )

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw TaxonomyProbeError.unableToWriteTempFile
        }
    }

    public static func unzipPath() throws -> String {
        let candidates = [
            "/usr/bin/unzip",
            "/bin/unzip",
            "/opt/homebrew/bin/unzip",
            "/usr/local/bin/unzip"
        ]

        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        throw TaxonomyProbeError.commandUnavailable("unzip")
    }
}

public func runCommand(
    _ launchPath: String,
    _ arguments: [String]
) throws -> String {
    try TaxonomyProber.runCommand(
        launchPath,
        arguments
    )
}

public func writeTempFile(
    data: Data,
    suffix: String
) throws -> URL {
    try TaxonomyProber.writeTempFile(
        data: data,
        suffix: suffix
    )
}

public func unzipPath() throws -> String {
    try TaxonomyProber.unzipPath()
}

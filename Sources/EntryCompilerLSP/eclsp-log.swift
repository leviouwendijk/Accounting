import Foundation

enum ECLSPLog {
    static func write(
        _ message: String
    ) {
        let timestamp = String(format: "%.6f", Date().timeIntervalSince1970)
        let line = "[eclsp \(timestamp)] \(message)\n"

        guard let data = line.data(using: .utf8) else {
            return
        }

        FileHandle.standardError.write(data)
    }
}

func eclspLog(
    _ message: String
) {
    ECLSPLog.write(message)
}

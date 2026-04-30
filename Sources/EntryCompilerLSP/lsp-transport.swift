import Foundation
import Darwin

final class LSPTransport {
    private let inputFD: Int32
    private let output: FileHandle

    init(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) {
        self.inputFD = input.fileDescriptor
        self.output = output
    }

    func nextMessage() -> [String: Any]? {
        guard let headerData = readHeader() else {
            eclspLog("transport.nextMessage: EOF before header")
            return nil
        }

        guard let header = String(data: headerData, encoding: .utf8) else {
            eclspLog("transport.nextMessage: header decode failed")
            return nil
        }

        let compactHeader = header.replacingOccurrences(of: "\r\n", with: " | ")
        eclspLog("transport.nextMessage: header \(compactHeader)")

        guard let contentLength = parseContentLength(from: header) else {
            eclspLog("transport.nextMessage: missing Content-Length")
            return nil
        }

        eclspLog("transport.nextMessage: contentLength=\(contentLength)")

        guard let body = readExactly(count: contentLength) else {
            eclspLog("transport.nextMessage: failed reading body")
            return nil
        }

        eclspLog("transport.nextMessage: bodyBytes=\(body.count)")

        guard let json = try? JSONSerialization.jsonObject(with: body) else {
            let preview = String(data: body.prefix(200), encoding: .utf8) ?? "<non-utf8>"
            eclspLog("transport.nextMessage: body JSON parse failed preview=\(preview)")
            return nil
        }

        guard let dict = json as? [String: Any] else {
            eclspLog("transport.nextMessage: body JSON not dict")
            return nil
        }

        let method = dict["method"] as? String ?? "<response>"
        let idText = dict["id"].map(String.init(describing:)) ?? "nil"
        eclspLog("transport.nextMessage: parsed method=\(method) id=\(idText)")

        return dict
    }

    func send(
        _ object: [String: Any]
    ) {
        let method = object["method"] as? String ?? "<response>"
        let idText = object["id"].map(String.init(describing:)) ?? "nil"
        eclspLog("transport.send: begin method=\(method) id=\(idText)")

        guard JSONSerialization.isValidJSONObject(object) else {
            eclspLog("transport.send: invalid json object")
            return
        }

        guard let body = try? JSONSerialization.data(withJSONObject: object) else {
            eclspLog("transport.send: json serialization failed")
            return
        }

        let header = "Content-Length: \(body.count)\r\n\r\n"

        guard let headerData = header.data(using: .utf8) else {
            eclspLog("transport.send: header encoding failed")
            return
        }

        output.write(headerData)
        output.write(body)

        eclspLog("transport.send: wrote header=\(headerData.count) body=\(body.count)")
    }

    private func readHeader() -> Data? {
        var data = Data()
        let separator = Data("\r\n\r\n".utf8)

        while true {
            guard let byte = readOneByte() else {
                if data.isEmpty {
                    return nil
                }

                eclspLog("transport.readHeader: EOF mid-header bytes=\(data.count)")
                return nil
            }

            data.append(byte)

            if data.count >= separator.count, data.suffix(separator.count) == separator {
                data.removeLast(separator.count)
                eclspLog("transport.readHeader: bytes=\(data.count)")
                return data
            }
        }
    }

    private func parseContentLength(
        from header: String
    ) -> Int? {
        for line in header.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)

            guard parts.count == 2 else {
                continue
            }

            if parts[0].caseInsensitiveCompare("Content-Length") == .orderedSame {
                return Int(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }

        return nil
    }

    private func readExactly(
        count: Int
    ) -> Data? {
        var remaining = count
        var data = Data()
        data.reserveCapacity(count)

        var chunk = [UInt8](repeating: 0, count: 4096)

        while remaining > 0 {
            let wanted = min(remaining, chunk.count)

            let bytesRead = chunk.withUnsafeMutableBytes { rawBuffer in
                guard let base = rawBuffer.baseAddress else {
                    return -1
                }

                return Darwin.read(inputFD, base, wanted)
            }

            if bytesRead > 0 {
                data.append(chunk, count: bytesRead)
                remaining -= bytesRead
                eclspLog("transport.readExactly: read=\(bytesRead) remaining=\(remaining)")
                continue
            }

            if bytesRead == 0 {
                eclspLog("transport.readExactly: EOF remaining=\(remaining)")
                return nil
            }

            if errno == EINTR {
                continue
            }

            eclspLog("transport.readExactly: read error errno=\(errno)")
            return nil
        }

        return data
    }

    private func readOneByte() -> UInt8? {
        var byte: UInt8 = 0

        while true {
            let bytesRead = Darwin.read(inputFD, &byte, 1)

            if bytesRead > 0 {
                return byte
            }

            if bytesRead == 0 {
                return nil
            }

            if errno == EINTR {
                continue
            }

            eclspLog("transport.readOneByte: read error errno=\(errno)")
            return nil
        }
    }
}

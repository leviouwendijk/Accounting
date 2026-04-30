import Foundation

@main
struct ECLSPMain {
    static func main() {
        eclspLog("main:start")

        let server = ECLSPServer()
        server.run()

        eclspLog("main:end")
    }
}

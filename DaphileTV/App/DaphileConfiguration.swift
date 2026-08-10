import Foundation

struct DaphileConfiguration {
    let serverIP: String
    let port: Int

    init(
        serverIP: String,
        port: Int = 9000
    ) {
        self.serverIP = serverIP
        self.port = port
    }

    var baseURL: URL? {
        URL(string: "http://\(serverIP):\(port)")
    }

    var jsonRPCURL: URL? {
        URL(string: "http://\(serverIP):\(port)/jsonrpc.js")
    }
}


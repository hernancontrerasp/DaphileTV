import Foundation

struct DaphileAPI {

    private let session: URLSession
    private let serverIP: String
    private let port: Int

    init(
        serverIP: String,
        port: Int = 9000,
        session: URLSession = .shared
    ) {
        self.serverIP = serverIP
        self.port = port
        self.session = session
    }

    var pluginsURL: URL? {
        guard !serverIP.isEmpty else {
            return nil
        }

        return URL(
            string: "http://\(serverIP):\(port)/plugins"
        )
    }

    func request(
        playerID: String,
        command: [String]
    ) async throws -> Data {

        guard !serverIP.isEmpty else {
            throw DaphileError.invalidServer
        }

        guard let url = URL(
            string: "http://\(serverIP):\(port)/jsonrpc.js"
        ) else {
            throw DaphileError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: Any] = [
            "id": 1,
            "method": "slim.request",
            "params": [
                playerID,
                command
            ]
        ]

        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        do {

            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                throw DaphileError.invalidResponse
            }

            return data

        } catch let error as DaphileError {
            throw error

        } catch {

            throw DaphileError.network(error)
        }
    }
}

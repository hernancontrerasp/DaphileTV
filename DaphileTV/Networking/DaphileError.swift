import Foundation

enum DaphileError: LocalizedError {
    case invalidServer
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidServer:
            return "El servidor Daphile no está configurado."

        case .invalidURL:
            return "La dirección del servidor Daphile no es válida."

        case .invalidResponse:
            return "Daphile devolvió una respuesta no válida."

        case .httpStatus(let statusCode):
            return "Daphile devolvió el código HTTP \(statusCode)."

        case .network(let error):
            return "No se pudo conectar con Daphile: \(error.localizedDescription)"
        }
    }
}


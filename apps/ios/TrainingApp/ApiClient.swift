import Foundation

struct AuthTokens: Codable {
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String
    let refreshExpiresAt: Date
}

struct ApiClient {
    var baseURL: URL
    var session: URLSession = .shared

    func login(userName: String, password: String) async throws -> AuthTokens {
        try await post("auth/login", body: LoginRequest(userName: userName, password: password))
    }

    func refresh(using refreshToken: String) async throws -> AuthTokens {
        try await post("auth/refresh", body: RefreshRequest(refreshToken: refreshToken))
    }

    func bootstrap(accessToken: String) async throws -> BootstrapResponse {
        var request = URLRequest(url: baseURL.appending(path: "bootstrap"))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ApiError.invalidResponse }
        guard http.statusCode != 401 else { throw ApiError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw ApiError.invalidResponse }
        return try JSONDecoder.api.decode(BootstrapResponse.self, from: data)
    }

    private func post<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.api.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ApiError.unauthorized
        }
        return try JSONDecoder.api.decode(Response.self, from: data)
    }
}

enum ApiError: LocalizedError {
    case invalidBaseURL
    case unauthorized
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: "Некорректный адрес API"
        case .unauthorized: "Неверный логин, пароль или истёкшая сессия"
        case .invalidResponse: "Сервер вернул неожиданный ответ"
        }
    }
}

private struct LoginRequest: Encodable { let userName: String; let password: String }
private struct RefreshRequest: Encodable { let refreshToken: String }

private extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { value in
            let container = try value.singleValueContainer()
            let string = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: string) { return date }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
        }
        return decoder
    }
}

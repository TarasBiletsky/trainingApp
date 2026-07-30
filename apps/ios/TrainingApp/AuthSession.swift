import Foundation

@MainActor
final class AuthSession: ObservableObject {
    @Published private(set) var tokens = KeychainStore.load()
    @Published var errorMessage: String?
    @Published var isLoading = false

    var isAuthenticated: Bool { tokens != nil }

    func login(baseURL: String, userName: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let tokens = try await client(baseURL).login(userName: userName, password: password)
            try KeychainStore.save(tokens)
            self.tokens = tokens
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func validAccessToken(baseURL: String) async throws -> String {
        guard let tokens else { throw ApiError.unauthorized }
        if tokens.expiresAt.timeIntervalSinceNow > 60 { return tokens.accessToken }
        let refreshed = try await client(baseURL).refresh(using: tokens.refreshToken)
        try KeychainStore.save(refreshed)
        self.tokens = refreshed
        return refreshed.accessToken
    }

    func bootstrap(baseURL: String) async throws -> BootstrapResponse {
        let token = try await validAccessToken(baseURL: baseURL)
        return try await client(baseURL).bootstrap(accessToken: token)
    }

    func send(_ path: String, method: String, baseURL: String) async throws {
        let token = try await validAccessToken(baseURL: baseURL)
        try await client(baseURL).send(path, method: method, accessToken: token)
    }

    func send<Request: Encodable>(_ path: String, method: String, body: Request, baseURL: String) async throws {
        let token = try await validAccessToken(baseURL: baseURL)
        try await client(baseURL).send(path, method: method, body: body, accessToken: token)
    }

    func logout() {
        KeychainStore.clear()
        tokens = nil
    }

    private func client(_ value: String) throws -> ApiClient {
        guard let url = URL(string: value), url.scheme != nil else { throw ApiError.invalidBaseURL }
        return ApiClient(baseURL: url)
    }
}

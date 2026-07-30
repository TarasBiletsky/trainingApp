import Foundation
import Security

enum KeychainStore {
    private static let service = "dev.taras.TrainingApp"
    private static let account = "authTokens"

    static func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let query = keychainQuery
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw URLError(.cannotCreateFile)
        }
    }

    static func load() -> AuthTokens? {
        var query = keychainQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    static func clear() { SecItemDelete(keychainQuery as CFDictionary) }

    private static var keychainQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

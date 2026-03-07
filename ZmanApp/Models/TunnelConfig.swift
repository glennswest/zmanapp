import Foundation

struct TunnelConfig: Codable, Hashable {
    var baseURL: String
    var apiToken: String
    var refreshToken: String
    var isConnected: Bool

    init(
        baseURL: String = "",
        apiToken: String = "",
        refreshToken: String = "",
        isConnected: Bool = false
    ) {
        self.baseURL = baseURL
        self.apiToken = apiToken
        self.refreshToken = refreshToken
        self.isConnected = isConnected
    }

    var isConfigured: Bool {
        !baseURL.isEmpty && !apiToken.isEmpty
    }
}

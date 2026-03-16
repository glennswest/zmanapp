import Foundation

@MainActor
final class CloudService: ObservableObject, Sendable {
    static let shared = CloudService()

    private let cloudBaseURL = "https://cloud.zmanapp.com"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - App Connect (send magic link)

    func connect(email: String) async throws -> AppConnectResponse {
        let body = AppConnectRequest(email: email)
        return try await post("/api/app/connect", body: body)
    }

    // MARK: - App Poll (check for claim token)

    func poll(email: String) async throws -> AppPollResponse {
        let body = AppPollRequest(email: email)
        return try await post("/api/app/poll", body: body)
    }

    // MARK: - Claim (exchange claim token at hub for API key)

    func claim(hubURL: String, claimToken: String) async throws -> ClaimResponse {
        let body = ClaimRequest(claimToken: claimToken)
        let url = hubURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return try await post("/api/v1/auth/claim", body: body, baseURL: url)
    }

    // MARK: - HTTP

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B, baseURL: String? = nil) async throws -> T {
        let base = baseURL ?? cloudBaseURL
        guard let url = URL(string: base + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "CloudService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 403:
            let message = String(data: data, encoding: .utf8)
            throw APIError.serverError(403, message)
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }
}

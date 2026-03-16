import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case unauthorized
    case serverError(Int, String?)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Server not configured. Add your Zman server in Settings."
        case .invalidURL:
            "Invalid server URL."
        case .unauthorized:
            "Authentication failed. Please sign in again."
        case .serverError(let code, let message):
            "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            "Data error: \(error.localizedDescription)"
        }
    }
}

@MainActor
final class APIService: ObservableObject, Sendable {
    @Published var isAuthenticated = false
    @Published var isConnected = false

    private var baseURL: String = ""
    private var apiKey: String = ""
    private var accessToken: String = ""
    private var refreshToken: String = ""
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    static let shared = APIService()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Configuration

    func configure(baseURL: String, apiKey: String = "", accessToken: String = "", refreshToken: String = "") {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.apiKey = apiKey
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isAuthenticated = !apiKey.isEmpty || !accessToken.isEmpty
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> AuthToken {
        let request = LoginRequest(username: username, password: password)
        let token: AuthToken = try await post("/api/v1/auth/login", body: request)
        self.accessToken = token.accessToken
        self.refreshToken = token.refreshToken
        self.isAuthenticated = true
        return token
    }

    func logout() {
        apiKey = ""
        accessToken = ""
        refreshToken = ""
        isAuthenticated = false
    }

    // MARK: - Buildings

    func fetchBuildings() async throws -> [Building] {
        try await get("/api/v1/buildings")
    }

    func fetchBuilding(id: String) async throws -> Building {
        try await get("/api/v1/buildings/\(id)")
    }

    // MARK: - Areas

    func fetchAreas(buildingId: String) async throws -> [Area] {
        try await get("/api/v1/buildings/\(buildingId)/areas")
    }

    func fetchArea(buildingId: String, areaId: String) async throws -> Area {
        try await get("/api/v1/buildings/\(buildingId)/areas/\(areaId)")
    }

    // MARK: - Device Commands

    func sendDeviceCommand(deviceId: String, command: String) async throws {
        var request = try buildRequest(path: "/api/v1/devices/\(deviceId)/command", method: "POST")
        request.httpBody = try encoder.encode(DeviceCommand(command: command))
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        switch http.statusCode {
        case 200...299:
            return // success
        case 401:
            isAuthenticated = false
            throw APIError.unauthorized
        default:
            let body = String(data: data, encoding: .utf8)
            throw APIError.serverError(http.statusCode, body)
        }
    }

    // MARK: - Health

    func checkConnection() async -> Bool {
        guard !baseURL.isEmpty else { return false }
        guard let url = URL(string: baseURL + "/api/v1/health") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        } else if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (_, response) = try await session.data(for: request)
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            isConnected = ok
            return ok
        } catch {
            isConnected = false
            return false
        }
    }

    // MARK: - HTTP Methods

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "GET")
        return try await execute(request)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = try buildRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request)
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        } else if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let url = request.url?.absoluteString ?? "?"
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                let raw = String(data: data.prefix(500), encoding: .utf8) ?? "<binary>"
                throw APIError.serverError(httpResponse.statusCode, "\(url)\nDecode failed: \(error.localizedDescription)\nBody: \(raw)")
            }
        case 401:
            isAuthenticated = false
            throw APIError.unauthorized
        default:
            let body = String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, "\(url)\n\(body ?? "")")
        }
    }
}

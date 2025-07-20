import Foundation

// Simple Supabase client implementation using URLSession
class SimpleSupabaseClient {
    let baseURL: String
    let apiKey: String
    private var accessToken: String?
    
    init(url: String, key: String) {
        self.baseURL = url
        self.apiKey = key
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String, metadata: [String: Any]? = nil) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/v1/signup"
        var body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        if let metadata = metadata {
            body["data"] = metadata
        }
        
        let response: AuthResponse = try await makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: body
        )
        
        self.accessToken = response.accessToken
        return response
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/v1/token?grant_type=password"
        let body = [
            "email": email,
            "password": password
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: body
        )
        
        self.accessToken = response.accessToken
        return response
    }
    
    func signOut() async throws {
        let endpoint = "\(baseURL)/auth/v1/logout"
        
        // Clear token first
        let token = self.accessToken
        self.accessToken = nil
        
        // Try to sign out on server
        do {
            let _: EmptyResponse = try await makeRequest(
                endpoint: endpoint,
                method: "POST",
                body: nil,
                token: token
            )
        } catch {
            // Even if server signout fails, we've cleared local token
            print("Server signout failed: \(error)")
        }
    }
    
    func getUser() async throws -> UserResponse? {
        guard let token = accessToken else { return nil }
        
        let endpoint = "\(baseURL)/auth/v1/user"
        let response: UserResponse = try await makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: nil,
            token: token
        )
        
        return response
    }
    
    // MARK: - Database Methods
    
    func from(_ table: String) -> DatabaseQueryBuilder {
        return DatabaseQueryBuilder(client: self, table: table)
    }
    
    // MARK: - Internal Request Method
    
    func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]?,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        if let token = token ?? accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseClientError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            if let errorData = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw SupabaseClientError.apiError(errorData.message ?? "Unknown error")
            }
            throw SupabaseClientError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Database Query Builder

class DatabaseQueryBuilder {
    private let client: SimpleSupabaseClient
    private let table: String
    private var filters: [(String, String, Any)] = []
    private var selectColumns: String = "*"
    
    init(client: SimpleSupabaseClient, table: String) {
        self.client = client
        self.table = table
    }
    
    func select(_ columns: String = "*") -> Self {
        self.selectColumns = columns
        return self
    }
    
    func eq(_ column: String, value: Any) -> Self {
        filters.append((column, "eq", value))
        return self
    }
    
    func insert(_ data: [String: Any]) async throws -> DatabaseResponse {
        let endpoint = "\(client.baseURL)/rest/v1/\(table)"
        return try await client.makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: data
        )
    }
    
    func execute() async throws -> DatabaseResponse {
        var endpoint = "\(client.baseURL)/rest/v1/\(table)?select=\(selectColumns)"
        
        for (column, op, value) in filters {
            endpoint += "&\(column)=\(op).\(value)"
        }
        
        return try await client.makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: nil
        )
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: UserResponse
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct UserResponse: Codable {
    let id: String
    let email: String?
    let phone: String?
    let createdAt: String
    let updatedAt: String
    let userMetadata: [String: Any]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userMetadata = "user_metadata"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        if let metadataData = try? container.decode(Data.self, forKey: .userMetadata),
           let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
            userMetadata = metadata
        } else {
            userMetadata = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let metadata = userMetadata,
           let metadataData = try? JSONSerialization.data(withJSONObject: metadata) {
            try container.encode(metadataData, forKey: .userMetadata)
        }
    }
}

struct DatabaseResponse: Codable {
    let data: Data?
    let error: String?
}

struct EmptyResponse: Codable {}

struct SupabaseErrorResponse: Codable {
    let message: String?
    let code: String?
}

// MARK: - Errors

enum SupabaseClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noAccessToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .noAccessToken:
            return "No access token available"
        }
    }
}

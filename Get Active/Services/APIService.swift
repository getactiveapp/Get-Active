import Foundation

/// API Service layer for backend communication
/// This provides a foundation for integrating with a backend API
class APIService {
    static let shared = APIService()
    
    // MARK: - Configuration
    
    /// Base URL for your API
    /// Update this when you set up your backend
    private var baseURL: String {
        // For development, you can use a local server
        // For production, use your actual API URL
        if let url = ProcessInfo.processInfo.environment["API_BASE_URL"], !url.isEmpty {
            return url
        }
        // Default: Update this to your actual API URL
        return "https://api.getactive.app" // Replace with your actual API URL
    }
    
    private let secureKeyManager = SecureKeyManager.shared
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Authentication Endpoints
    
    /// Sign up a new user
    func signUp(email: String, username: String, password: String, university: String?, accountType: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let endpoint = "/api/auth/signup"
        let body: [String: Any] = [
            "email": email,
            "username": username,
            "password": password, // Backend should hash this
            "university": university ?? "",
            "accountType": accountType
        ]
        
        request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                    // Save tokens to Keychain
                    if let token = response.token {
                        self.secureKeyManager.saveAuthToken(token)
                    }
                    if let refreshToken = response.refreshToken {
                        self.secureKeyManager.saveRefreshToken(refreshToken)
                    }
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Login user
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let endpoint = "/api/auth/login"
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                    // Save tokens to Keychain
                    if let token = response.token {
                        self.secureKeyManager.saveAuthToken(token)
                    }
                    if let refreshToken = response.refreshToken {
                        self.secureKeyManager.saveRefreshToken(refreshToken)
                    }
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Verify 2FA code
    func verify2FA(code: String, userId: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let endpoint = "/api/auth/verify-2fa"
        let body: [String: Any] = [
            "code": code,
            "userId": userId
        ]
        
        request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                    // Save tokens to Keychain
                    if let token = response.token {
                        self.secureKeyManager.saveAuthToken(token)
                    }
                    if let refreshToken = response.refreshToken {
                        self.secureKeyManager.saveRefreshToken(refreshToken)
                    }
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Send 2FA code
    func send2FACode(email: String, completion: @escaping (Result<Bool, APIError>) -> Void) {
        let endpoint = "/api/auth/send-2fa"
        let body: [String: Any] = [
            "email": email
        ]
        
        request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Refresh authentication token
    func refreshToken(completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        guard let refreshToken = secureKeyManager.getRefreshToken() else {
            completion(.failure(.unauthorized))
            return
        }
        
        let endpoint = "/api/auth/refresh"
        let body: [String: Any] = [
            "refreshToken": refreshToken
        ]
        
        request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                    if let token = response.token {
                        self.secureKeyManager.saveAuthToken(token)
                    }
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Delete user account
    func deleteAccount(completion: @escaping (Result<Bool, APIError>) -> Void) {
        let endpoint = "/api/auth/account"
        
        request(endpoint: endpoint, method: "DELETE", body: nil, requiresAuth: true) { result in
            switch result {
            case .success:
                // Clear all tokens
                self.secureKeyManager.clearAll()
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Endpoints
    
    /// Get user profile
    func getUserProfile(completion: @escaping (Result<User, APIError>) -> Void) {
        let endpoint = "/api/user/profile"
        
        request(endpoint: endpoint, method: "GET", body: nil, requiresAuth: true) { result in
            switch result {
            case .success(let data):
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    completion(.success(user))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update user profile
    func updateUserProfile(_ user: User, completion: @escaping (Result<User, APIError>) -> Void) {
        let endpoint = "/api/user/profile"
        
        do {
            let body = try JSONEncoder().encode(user)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            
            request(endpoint: endpoint, method: "PUT", body: json, requiresAuth: true) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedUser = try JSONDecoder().decode(User.self, from: data)
                        completion(.success(updatedUser))
                    } catch {
                        completion(.failure(.decodingError(error)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Generic Request Method
    
    private func request(endpoint: String, method: String, body: [String: Any]?, requiresAuth: Bool, completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if required
        if requiresAuth {
            if let token = secureKeyManager.getAuthToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                // Try to refresh token
                refreshToken { result in
                    switch result {
                    case .success:
                        // Retry request with new token
                        self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth, completion: completion)
                    case .failure:
                        completion(.failure(.unauthorized))
                    }
                }
                return
            }
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(.failure(.encodingError(error)))
                return
            }
        }
        
        // Make request
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                } else {
                    completion(.failure(.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let token: String?
    let refreshToken: String?
    let user: User?
    let requires2FA: Bool?
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case unauthorized
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

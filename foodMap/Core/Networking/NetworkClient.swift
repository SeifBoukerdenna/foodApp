import Foundation
import Combine
import FirebaseAuth

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case unknown(Error)
    case authenticationRequired
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Could not process data from server"
        case .unknown(let error):
            return error.localizedDescription
        case .authenticationRequired:
            return "Authentication is required"
        case .tokenExpired:
            return "Authentication token expired, please login again"
        }
    }
}

class NetworkClient {
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    private var tokenExpirationDate: Date?
    
    // MARK: - Initializer
    init(baseURLString: String, session: URLSession = .shared) {
        self.baseURL = baseURLString
        self.session = session
        
        print("NetworkClient initialized with base URL: \(baseURL)")
    }
    
    // MARK: - Request Methods
    func get<T: Decodable>(endpoint: String, requiresAuth: Bool = false) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        if requiresAuth {
            return getValidAuthToken()
                .flatMap { token -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add auth token
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    print("GET request to: \(url.absoluteString)")
                    print("With token: \(token.prefix(15))...")
                    return self.executeRequest(request)
                }
                .eraseToAnyPublisher()
        } else {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("GET request to: \(url.absoluteString)")
            return executeRequest(request)
        }
    }
    
    func post<T: Decodable, E: Encodable>(endpoint: String, body: E, requiresAuth: Bool = false) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            print("❌ Invalid URL: \(baseURL)/\(endpoint)")
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        if requiresAuth {
            // Get auth token before making the request
            return getValidAuthToken()
                .flatMap { token -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    // Add auth token
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    print("Using token: \(token.prefix(15))...")
                    
                    do {
                        let encoder = JSONEncoder()
                        let jsonData = try encoder.encode(body)
                        request.httpBody = jsonData
                        
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("📤 POST request to: \(url.absoluteString)")
                            print("📦 Request body: \(jsonString)")
                        }
                    } catch {
                        print("❌ Error encoding request body: \(error)")
                        return Fail(error: error).eraseToAnyPublisher()
                    }
                    
                    return self.executeRequest(request)
                        .tryCatch { error -> AnyPublisher<T, Error> in
                            // If token expired, try getting a new token and retry
                            if case NetworkError.httpError(401) = error {
                                print("⚠️ Token expired, refreshing and retrying")
                                self.authToken = nil
                                self.tokenExpirationDate = nil
                                
                                return self.getValidAuthToken()
                                    .flatMap { newToken -> AnyPublisher<T, Error> in
                                        var newRequest = request
                                        newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                                        return self.executeRequest(newRequest)
                                    }
                                    .eraseToAnyPublisher()
                            }
                            throw error
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else {
            // Original implementation without auth
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(body)
                request.httpBody = jsonData
                
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📤 POST request to: \(url.absoluteString)")
                    print("📦 Request body: \(jsonString)")
                }
            } catch {
                print("❌ Error encoding request body: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            
            return executeRequest(request)
        }
    }
    
    // MARK: - Helper Methods
    private func executeRequest<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw NetworkError.invalidResponse
                }
                
                print("📥 Response status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 401 {
                    print("❌ Authentication required or token expired")
                    throw NetworkError.httpError(401)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP error: \(httpResponse.statusCode)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    print("❌ Decoding error: \(decodingError)")
                    return NetworkError.decodingError(decodingError)
                } else {
                    print("❌ Other error: \(error)")
                    return NetworkError.unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Get a valid authentication token (either cached or fresh)
    private func getValidAuthToken() -> AnyPublisher<String, Error> {
        // If we have a non-expired token, use it
        if let token = authToken, let expiration = tokenExpirationDate, expiration > Date() {
            print("✅ Using cached token, expires: \(expiration)")
            return Just(token)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise, get a fresh token
        return refreshAuthToken()
    }
    
    // Get a fresh authentication token from Firebase
    private func refreshAuthToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            guard let currentUser = Auth.auth().currentUser else {
                print("❌ No authenticated user found")
                promise(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // Force token refresh
            currentUser.getIDTokenForcingRefresh(true) { token, error in
                if let error = error {
                    print("❌ Failed to get ID token: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                guard let token = token else {
                    print("❌ Token is nil")
                    promise(.failure(NetworkError.authenticationRequired))
                    return
                }
                
                // Cache the token with expiration (tokens typically last 1 hour)
                self.authToken = token
                self.tokenExpirationDate = Date().addingTimeInterval(3600) // 1 hour from now
                
                print("✅ Successfully retrieved fresh auth token")
                promise(.success(token))
            }
        }.eraseToAnyPublisher()
    }
}

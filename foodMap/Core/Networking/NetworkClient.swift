import Foundation
import Combine
import FirebaseAuth
import FirebaseAppCheck

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case unknown(Error)
    case authenticationRequired
    case tokenExpired
    case appCheckError
    
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
        case .appCheckError:
            return "App verification failed - please try again later"
        }
    }
}

class NetworkClient {
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    private var tokenExpirationDate: Date?
    private var appCheckToken: String?
    private var appCheckTokenExpiration: Date?
    
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
            return Publishers.Zip(
                getValidAuthToken(),
                getValidAppCheckToken()
            )
            .flatMap { authToken, appCheckToken -> AnyPublisher<T, Error> in
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Add auth token
                request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                
                // Add App Check token
                request.addValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                
                print("GET request to: \(url.absoluteString)")
                print("With auth token: \(authToken.prefix(15))...")
                print("With App Check token: \(appCheckToken.prefix(15))...")
                
                return self.executeRequest(request)
            }
            .eraseToAnyPublisher()
        } else {
            return getValidAppCheckToken()
                .flatMap { appCheckToken -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add App Check token even for non-auth requests
                    request.addValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                    
                    print("GET request to: \(url.absoluteString)")
                    print("With App Check token: \(appCheckToken.prefix(15))...")
                    
                    return self.executeRequest(request)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func post<T: Decodable, E: Encodable>(endpoint: String, body: E, requiresAuth: Bool = false) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            print("❌ Invalid URL: \(baseURL)/\(endpoint)")
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        if requiresAuth {
            // Get both auth token and App Check token before making the request
            return Publishers.Zip(
                getValidAuthToken(),
                getValidAppCheckToken()
            )
            .flatMap { authToken, appCheckToken -> AnyPublisher<T, Error> in
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                // Add auth token
                request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                
                // Add App Check token
                request.addValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                
                print("Using auth token: \(authToken.prefix(15))...")
                print("Using App Check token: \(appCheckToken.prefix(15))...")
                
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
                        // If token expired, try refreshing both tokens and retry
                        if case NetworkError.httpError(401) = error {
                            print("⚠️ Token expired, refreshing and retrying")
                            self.authToken = nil
                            self.tokenExpirationDate = nil
                            self.appCheckToken = nil
                            self.appCheckTokenExpiration = nil
                            
                            return Publishers.Zip(
                                self.refreshAuthToken(),
                                self.refreshAppCheckToken()
                            )
                            .flatMap { newAuthToken, newAppCheckToken -> AnyPublisher<T, Error> in
                                var newRequest = request
                                newRequest.setValue("Bearer \(newAuthToken)", forHTTPHeaderField: "Authorization")
                                newRequest.setValue(newAppCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
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
            // For non-auth requests, still use App Check
            return getValidAppCheckToken()
                .flatMap { appCheckToken -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    // Add App Check token even for non-auth requests
                    request.addValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                    
                    print("Using App Check token: \(appCheckToken.prefix(15))...")
                    
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
                            // Fixed: Separate if cases for different error codes
                            if case NetworkError.httpError(401) = error {
                                print("⚠️ App Check token may be invalid (401), refreshing and retrying")
                                self.appCheckToken = nil
                                self.appCheckTokenExpiration = nil
                                
                                return self.refreshAppCheckToken()
                                    .flatMap { newAppCheckToken -> AnyPublisher<T, Error> in
                                        var newRequest = request
                                        newRequest.setValue(newAppCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                                        return self.executeRequest(newRequest)
                                    }
                                    .eraseToAnyPublisher()
                            } else if case NetworkError.httpError(403) = error {
                                print("⚠️ App Check token may be invalid (403), refreshing and retrying")
                                self.appCheckToken = nil
                                self.appCheckTokenExpiration = nil
                                
                                return self.refreshAppCheckToken()
                                    .flatMap { newAppCheckToken -> AnyPublisher<T, Error> in
                                        var newRequest = request
                                        newRequest.setValue(newAppCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
                                        return self.executeRequest(newRequest)
                                    }
                                    .eraseToAnyPublisher()
                            }
                            throw error
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
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
                
                if httpResponse.statusCode == 403 {
                    print("❌ App Check verification failed")
                    throw NetworkError.httpError(403)
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
            print("✅ Using cached auth token, expires: \(expiration)")
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
    
    // Get a valid App Check token (either cached or fresh)
    private func getValidAppCheckToken() -> AnyPublisher<String, Error> {
        // If we have a non-expired App Check token, use it
        if let token = appCheckToken, let expiration = appCheckTokenExpiration, expiration > Date() {
            print("✅ Using cached App Check token, expires: \(expiration)")
            return Just(token)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise, get a fresh App Check token
        return refreshAppCheckToken()
    }
    
    // Get a fresh App Check token
    private func refreshAppCheckToken() -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            AppCheck.appCheck().token(forcingRefresh: true) { token, error in
                if let error = error {
                    print("❌ Failed to get App Check token: \(error.localizedDescription)")
                    promise(.failure(NetworkError.appCheckError))
                    return
                }
                
                guard let token = token else {
                    print("❌ App Check token is nil")
                    promise(.failure(NetworkError.appCheckError))
                    return
                }
                
                // Cache the App Check token with its expiration
                self.appCheckToken = token.token
                self.appCheckTokenExpiration = token.expirationDate
                
                print("✅ Successfully retrieved fresh App Check token")
                print("✅ App Check token expires: \(token.expirationDate)")
                
                promise(.success(token.token))
            }
        }.eraseToAnyPublisher()
    }
}

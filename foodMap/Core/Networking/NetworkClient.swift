import Foundation
import Combine

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case unknown(Error)
    
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
        }
    }
}

class NetworkClient {
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    
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
            return AppEnvironment.shared.getAuthHeaders()
                .flatMap { authHeaders -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add auth headers
                    for (key, value) in authHeaders {
                        request.addValue(value, forHTTPHeaderField: key)
                    }
                    
                    print("GET request to: \(url.absoluteString)")
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
            // Get auth headers before making the request
            return AppEnvironment.shared.getAuthHeaders()
                .flatMap { authHeaders -> AnyPublisher<T, Error> in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("*/*", forHTTPHeaderField: "Accept")
                    
                    // Add auth headers
                    for (key, value) in authHeaders {
                        request.addValue(value, forHTTPHeaderField: key)
                    }
                    
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
                }
                .eraseToAnyPublisher()
        } else {
            // Original implementation without auth
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("*/*", forHTTPHeaderField: "Accept")
            
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
}

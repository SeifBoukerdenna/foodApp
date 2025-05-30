import Foundation
import Combine
import CoreLocation

// MARK: - Protocol
protocol MapsServiceProtocol {
    func searchPlaces(request: PlaceSearchRequest) -> AnyPublisher<PlaceSearchResponse, Error>
    func getPlaceDetails(request: PlaceDetailsRequest) -> AnyPublisher<PlaceDetailsResult, Error>
    func getDirections(request: DirectionsRequest) -> AnyPublisher<DirectionsResponse, Error>
    func getPhotoUrl(photoReference: String, maxWidth: Int) -> AnyPublisher<PhotoUrlResponse, Error>
}

// MARK: - Request/Response Models
struct PlaceSearchRequest: Codable {
    let query: String
    let latitude: Double?
    let longitude: Double?
    let radius: Int?
    let type: String?
}

struct PlaceSearchResponse: Codable {
    let results: [PlaceResult]
    let status: String
}

struct PlaceResult: Codable, Identifiable {
    let id = UUID()
    let placeId: String
    let name: String
    let address: String
    let rating: Double?
    let priceLevel: Int?
    let photos: [PlacePhoto]
    let geometry: PlaceGeometry
    let types: [String]
    let openingHours: OpeningHours?
    
    var location: CLLocationCoordinate2D? {
        guard let lat = geometry.location.lat,
              let lng = geometry.location.lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    enum CodingKeys: String, CodingKey {
        case placeId, name, address, rating, priceLevel, photos, geometry, types, openingHours
    }
}

struct PlacePhoto: Codable {
    let photoReference: String
    let width: Int
    let height: Int
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double?
    let lng: Double?
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}

struct PlaceDetailsRequest: Codable {
    let placeId: String
}

struct PlaceDetailsResult: Codable {
    let placeId: String
    let name: String
    let address: String
    let rating: Double?
    let priceLevel: Int?
    let phoneNumber: String?
    let website: String?
    let photos: [PlacePhoto]
    let geometry: PlaceGeometry
    let openingHours: OpeningHours?
    let reviews: [PlaceReview]
    let types: [String]
}

struct PlaceReview: Codable {
    let authorName: String
    let rating: Int
    let text: String
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating, text, time
    }
}

struct DirectionsRequest: Codable {
    let origin: String
    let destination: String
    let mode: String?
}

struct DirectionsResponse: Codable {
    let routes: [DirectionsRoute]
    let status: String
}

struct DirectionsRoute: Codable {
    let legs: [DirectionsLeg]
    let overviewPolyline: String
    let summary: String
    
    enum CodingKeys: String, CodingKey {
        case legs, summary
        case overviewPolyline = "overviewPolyline"
    }
}

struct DirectionsLeg: Codable {
    let distance: DirectionsDistance
    let duration: DirectionsDuration
    let startAddress: String
    let endAddress: String
    let steps: [DirectionsStep]
}

struct DirectionsDistance: Codable {
    let text: String
    let value: Int
}

struct DirectionsDuration: Codable {
    let text: String
    let value: Int
}

struct DirectionsStep: Codable {
    let distance: DirectionsDistance
    let duration: DirectionsDuration
    let instructions: String
    let startLocation: PlaceLocation
    let endLocation: PlaceLocation
}

struct PhotoUrlResponse: Codable {
    let url: String
}

// MARK: - Maps Service Implementation
class MapsService: MapsServiceProtocol, ObservableObject {
    private let networkClient: NetworkClient
    private let appEnvironment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()
    
    init(appEnvironment: AppEnvironment = AppEnvironment.shared) {
        self.appEnvironment = appEnvironment
        self.networkClient = NetworkClient(baseURLString: appEnvironment.apiBaseURL)
    }
    
    func searchPlaces(request: PlaceSearchRequest) -> AnyPublisher<PlaceSearchResponse, Error> {
        print("🔍 MapsService: Searching for '\(request.query)'")
        return networkClient.post(
            endpoint: "api/v1/maps/search",
            body: request,
            requiresAuth: true
        )
        .handleEvents(
            receiveOutput: { response in
                print("✅ MapsService: Got \(response.results.count) results from server")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ MapsService: Search failed - \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func getPlaceDetails(request: PlaceDetailsRequest) -> AnyPublisher<PlaceDetailsResult, Error> {
        return networkClient.post(
            endpoint: "api/v1/maps/place-details",
            body: request,
            requiresAuth: true
        )
    }
    
    func getDirections(request: DirectionsRequest) -> AnyPublisher<DirectionsResponse, Error> {
        return networkClient.post(
            endpoint: "api/v1/maps/directions",
            body: request,
            requiresAuth: true
        )
    }
    
    func getPhotoUrl(photoReference: String, maxWidth: Int = 400) -> AnyPublisher<PhotoUrlResponse, Error> {
        let endpoint = "api/v1/maps/photo?photoReference=\(photoReference)&maxWidth=\(maxWidth)"
        return networkClient.get(endpoint: endpoint, requiresAuth: true)
    }
}

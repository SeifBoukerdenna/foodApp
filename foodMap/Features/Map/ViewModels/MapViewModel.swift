import Foundation
import Combine
import CoreLocation
import GoogleMaps

class MapViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var searchResults: [PlaceResult] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var routePolyline: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let mapsService: MapsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentMapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.5741, longitude: -73.6921)
    private var currentZoom: Float = 13.0
    
    // MARK: - Initialization
    init(mapsService: MapsServiceProtocol = MapsService()) {
        self.mapsService = mapsService
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationServices() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Search Methods
    func searchPlaces(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔍 MapViewModel: Starting search for: '\(query)'")
        
        let request = PlaceSearchRequest(
            query: query,
            latitude: userLocation?.latitude,
            longitude: userLocation?.longitude,
            radius: 10000, // Increased radius to 10km
            type: nil // Don't restrict to just restaurants
        )
        
        print("📤 MapViewModel: Sending search request: \(request)")
        
        mapsService.searchPlaces(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = "Search failed: \(error.localizedDescription)"
                        print("❌ MapViewModel: Places search failed: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    print("📥 MapViewModel: Search response received with \(response.results.count) results")
                    self?.searchResults = response.results
                    self?.errorMessage = nil
                    
                    // Log first few results
                    for (index, result) in response.results.prefix(3).enumerated() {
                        print("  \(index + 1). \(result.name) at \(result.address)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func searchNearbyRestaurants() {
        guard let location = userLocation else {
            errorMessage = "Location not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔍 Searching for nearby restaurants")
        
        let request = PlaceSearchRequest(
            query: "restaurants near me",
            latitude: location.latitude,
            longitude: location.longitude,
            radius: 5000,
            type: "restaurant"
        )
        
        mapsService.searchPlaces(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self?.errorMessage = "Search failed: \(error.localizedDescription)"
                        print("❌ Nearby restaurants search failed: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.searchResults = response.results
                    self?.errorMessage = nil
                    print("✅ Found \(response.results.count) nearby restaurants")
                }
            )
            .store(in: &cancellables)
    }
    
    func getPlaceDetails(placeId: String) -> AnyPublisher<PlaceDetailsResult, Error> {
        let request = PlaceDetailsRequest(placeId: placeId)
        return mapsService.getPlaceDetails(request: request)
    }
    
    func getDirections(to place: PlaceResult) {
        guard let userLocation = userLocation,
              let placeLocation = place.location else {
            errorMessage = "Location not available"
            return
        }
        
        let origin = "\(userLocation.latitude),\(userLocation.longitude)"
        let destination = "\(placeLocation.latitude),\(placeLocation.longitude)"
        
        let request = DirectionsRequest(
            origin: origin,
            destination: destination,
            mode: "walking"
        )
        
        mapsService.getDirections(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.errorMessage = "Failed to get directions: \(error.localizedDescription)"
                        print("❌ Directions failed: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    if let route = response.routes.first {
                        self?.routePolyline = route.overviewPolyline
                        print("✅ Got directions to \(place.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Map Updates
    func updateMapRegion(center: CLLocationCoordinate2D, zoom: Float) {
        currentMapCenter = center
        currentZoom = zoom
    }
    
    func clearRoute() {
        routePolyline = nil
    }
    
    func clearSearchResults() {
        searchResults = []
        routePolyline = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location.coordinate
        print("📍 User location updated: \(location.coordinate)")
        
        // Stop updating after getting the first location
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        errorMessage = "Location error: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationServices()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services."
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

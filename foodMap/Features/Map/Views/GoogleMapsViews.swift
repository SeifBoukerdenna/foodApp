import SwiftUI
import GoogleMaps
import GooglePlaces
import CoreLocation

struct GoogleMapsView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    @Binding var selectedPlace: PlaceResult?
    @Binding var showingPlaceDetails: Bool
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: 45.5741,  // Laval coordinates
            longitude: -73.6921,
            zoom: 13.0
        )
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        // Configure map style
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.mapType = .normal
        
        // Set dark style
        if let path = Bundle.main.path(forResource: "MapStyle", ofType: "json"),
           let jsonString = try? String(contentsOfFile: path),
           let style = try? GMSMapStyle(jsonString: jsonString) {
            mapView.mapStyle = style
        }
        
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update user location
        if let userLocation = viewModel.userLocation {
            let camera = GMSCameraPosition.camera(
                withTarget: userLocation,
                zoom: mapView.camera.zoom
            )
            mapView.animate(to: camera)
        }
        
        // Clear existing markers
        mapView.clear()
        
        // Add place markers
        for place in viewModel.searchResults {
            if let location = place.location {
                let marker = GMSMarker()
                marker.position = location
                marker.title = place.name
                marker.snippet = place.address
                marker.userData = place
                marker.map = mapView
                
                // Custom marker icon for restaurants
                marker.icon = createCustomMarkerIcon(for: place)
            }
        }
        
        // Add route polyline if available
        if let routePolyline = viewModel.routePolyline {
            let path = GMSPath(fromEncodedPath: routePolyline)
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = UIColor(Color.brandRed)
            polyline.strokeWidth = 4.0
            polyline.map = mapView
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createCustomMarkerIcon(for place: PlaceResult) -> UIImage? {
        let isRestaurant = place.types.contains { type in
            ["restaurant", "food", "meal_takeaway", "cafe"].contains(type)
        }
        
        let iconName = isRestaurant ? "fork.knife.circle.fill" : "mappin.circle.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        
        return UIImage(systemName: iconName, withConfiguration: config)?
            .withTintColor(UIColor(Color.brandRed), renderingMode: .alwaysOriginal)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let place = marker.userData as? PlaceResult {
                parent.selectedPlace = place
                parent.showingPlaceDetails = true
            }
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            // Update the region in the view model
            parent.viewModel.updateMapRegion(
                center: position.target,
                zoom: position.zoom
            )
        }
    }
}

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import GoogleMaps
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Use DeviceCheck for both development and production on real devices
    let deviceCheckProvider = DeviceCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(deviceCheckProvider)
    print("✅ Using DeviceCheck provider for App Check")

    // Configure Google Maps and Places
    // Replace with your actual Google Maps API key
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["MAPS_API_KEY"] as? String {
        GMSServices.provideAPIKey(apiKey)
        GMSPlacesClient.provideAPIKey(apiKey)
        print("✅ Google Maps configured with API key")
    } else {
        // Fallback - you should add your API key here or in GoogleService-Info.plist
        let mapsApiKey = "AIzaSyAGYja99JlU03V-l3HJa281SEIdC_F-96Y"
        GMSServices.provideAPIKey(mapsApiKey)
        GMSPlacesClient.provideAPIKey(mapsApiKey)
        print("⚠️ Using fallback Google Maps API key")
    }

    return true
  }
}

@main
struct FoodMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appEnvironment = AppEnvironment.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
                .preferredColorScheme(.dark) // Force dark theme throughout
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure optional global settings
        configureKeyboardSettings()
        
        // Add default user ID if none exists
        if UserDefaults.standard.string(forKey: "userId") == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: "userId")
        }
        
        // Print app info
        #if DEBUG
        print("FoodMap app started in debug mode")
        // Verify App Check is working
        verifyAppCheckToken()
        #else
        print("FoodMap app started in release mode")
        #endif
    }
    
    // Use this method to configure keyboard handling
    private func configureKeyboardSettings() {
        // This disables automatic keyboard scrolling adjustment which causes layout issues
        UIScrollView.appearance().keyboardDismissMode = .interactive
    }
    
    // Test that App Check is working
    private func verifyAppCheckToken() {
        AppCheck.appCheck().token(forcingRefresh: true) { token, error in
            if let error = error {
                print("❌ App Check error: \(error.localizedDescription)")
                print("⚠️ App will continue without App Check")
            } else if let token = token {
                print("✅ App Check token successfully generated: \(token.token.prefix(15))...")
                print("✅ Token expires: \(token.expirationDate)")
            }
        }
    }
}

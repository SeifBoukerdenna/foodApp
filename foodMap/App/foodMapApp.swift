import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Use DeviceCheck for both development and production on real devices
    let deviceCheckProvider = DeviceCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(deviceCheckProvider)
    print("✅ Using DeviceCheck provider for App Check")

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

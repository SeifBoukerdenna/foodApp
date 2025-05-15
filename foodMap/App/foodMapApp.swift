import SwiftUI

@main
struct FoodMapApp: App {
    // Environment objects and state
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
        #else
        print("FoodMap app started in release mode")
        #endif
    }
    
    // Use this method to configure keyboard handling
    private func configureKeyboardSettings() {
        // This disables automatic keyboard scrolling adjustment which causes layout issues
        UIScrollView.appearance().keyboardDismissMode = .interactive
    }
}

//
//  foodMapApp.swift
//  FoodMap
//

import SwiftUI

@main
struct FoodMapApp: App {
    // Environment configuration
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Initialize environment and other app settings
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure NetworkClient with the proper URL
        // For physical devices, update the IP address in Configuration.swift
        
        // Set a default user ID if not already set
        if UserDefaults.standard.string(forKey: "userId") == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: "userId")
        }
    }
}

// App-wide state container
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    
    // Additional app-wide state can be added here
}

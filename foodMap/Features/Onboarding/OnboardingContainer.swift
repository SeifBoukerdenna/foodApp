//
//  OnboardingContainer.swift
//  FoodMap
//
//  Container for managing the onboarding flow
//

import SwiftUI
import FirebaseAuth

struct OnboardingContainer: View {
    // MARK: - Properties
    @State private var currentStep: OnboardingStep = .displayName
    @State private var displayName: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    enum OnboardingStep {
        case displayName
        case confirmName
        case welcome
        case home
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background color
            Color.brandRed.ignoresSafeArea()
            
            // Content based on current step
            switch currentStep {
            case .displayName:
                DisplayNameView(
                    displayName: $displayName,
                    onConfirm: {
                        updateUserDisplayName()
                        currentStep = .confirmName
                    }
                )
                
            case .confirmName:
                ConfirmNameView(
                    displayName: displayName,
                    onConfirm: { currentStep = .welcome },
                    onBack: { currentStep = .displayName }
                )
                
            case .welcome:
                WelcomeView(
                    displayName: displayName,
                    onExplore: { currentStep = .home }
                )
                
            case .home:
                HomeView(displayName: displayName)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    // Update the user's display name in Firebase
    private func updateUserDisplayName() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        
        changeRequest.commitChanges { error in
            if let error = error {
                print("❌ Failed to update display name: \(error.localizedDescription)")
            } else {
                print("✅ Display name updated successfully: \(displayName)")
                
                // Update the user in our view model
                if var currentUser = authViewModel.user {
                    currentUser.displayName = displayName
                    authViewModel.user = currentUser
                }
            }
        }
    }
}

// MARK: - Preview
struct OnboardingContainer_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainer()
            .environmentObject(AuthViewModel())
    }
}

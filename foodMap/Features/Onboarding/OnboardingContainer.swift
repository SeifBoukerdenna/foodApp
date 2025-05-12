//
//  OnboardingContainer.swift
//  FoodMap
//
//  Container for managing the onboarding flow
//

import SwiftUI

struct OnboardingContainer: View {
    // MARK: - Properties
    @State private var currentStep: OnboardingStep = .displayName
    @State private var displayName: String = ""
    
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
                    onConfirm: { currentStep = .confirmName }
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
            }
        }
    }
}

// MARK: - Preview
struct OnboardingContainer_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainer()
    }
}

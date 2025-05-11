//
//  OnboardingFlow.swift
//  FoodMap
//
//  Main container for the onboarding process
//

import SwiftUI

struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .displayName
    @State private var displayName: String = ""
    
    enum OnboardingStep {
        case displayName
        case confirmName
        case welcome
    }
    
    var body: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            
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
                    displayName: displayName
                )
            }
        }
    }
}

struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
    }
}

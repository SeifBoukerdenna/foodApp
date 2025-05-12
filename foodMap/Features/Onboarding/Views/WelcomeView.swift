//
//  WelcomeView.swift
//  FoodMap
//
//  Third screen of the onboarding process - welcome screen
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Properties
    let displayName: String
    var onExplore: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing - consistent across all screens
            Spacer().frame(height: 100)
            
            // 🐧 Chef Penguin
            Image("penguin_chef")
                .resizable()
                .scaledToFit()
                .frame(width: 170)
                .padding(.bottom, -18)
            
            // 💬 Bubble
            Text("Alright \(displayName), let's get started!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .shadow(radius: 4, y: 2)
                )
                .offset(y: -18)
            
            // Gap after bubble
            Spacer().frame(height: 32 + 18)
            
            Spacer()
            
            // Fun explore button
            Button(action: onExplore) {
                HStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20))
                    
                    Text("Show me the tasty treats, mighty penguin!")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.black)
                        .shadow(radius: 4, y: 2)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100) // Bottom padding for better positioning
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            WelcomeView(
                displayName: "FoodLover",
                onExplore: {}
            )
        }
    }
}

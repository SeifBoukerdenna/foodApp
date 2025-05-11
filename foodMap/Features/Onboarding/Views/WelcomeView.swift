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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 100)
    }
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            WelcomeView(displayName: "FoodLover")
        }
    }
}

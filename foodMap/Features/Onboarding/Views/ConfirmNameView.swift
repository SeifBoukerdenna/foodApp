//
//  ConfirmNameView.swift
//  FoodMap
//
//  Second screen of the onboarding process - confirming display name
//

import SwiftUI

struct ConfirmNameView: View {
    // MARK: - Properties
    let displayName: String
    let onConfirm: () -> Void
    let onBack: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // 🐧 Chef Penguin
            Image("penguin_explanation")
                .resizable()
                .scaledToFit()
                .frame(width: 170)
                .padding(.bottom, -18)
            
            // 💬 Bubble
            Text("So you're \"\(displayName)\", is that right?")
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
            
            // Yes/No buttons
            HStack(spacing: 16) {
                // Yes button
                Button(action: onConfirm) {
                    Text("Yes!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                
                // No button
                Button(action: onBack) {
                    Text("No...")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 100)
    }
}

// MARK: - Preview
struct ConfirmNameView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            ConfirmNameView(
                displayName: "FoodLover",
                onConfirm: {},
                onBack: {}
            )
        }
    }
}

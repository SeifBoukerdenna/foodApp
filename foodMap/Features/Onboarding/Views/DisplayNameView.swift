//
//  DisplayNameView.swift
//  FoodMap
//
//  First screen of the onboarding process - asking for display name
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
    }
}
#endif

struct DisplayNameView: View {
    // MARK: - Properties
    @Binding var displayName: String
    var onConfirm: () -> Void
    @State private var keyboardIsVisible = false
    
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top spacing - consistent across all screens
                Spacer().frame(height: 100)
                
                // 🐧 Chef Penguin
                Image("penguin_explanation")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
                    .padding(.bottom, -18)
                
                // 💬 Bubble
                Text("Nice to meet you! What should I call you?\n(This will be your displayed name on FoodMap)")
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
                
                // Gap after bubble - consistent across screens
                Spacer().frame(height: 32 + 18)
                
                // Display Name field
                ZStack(alignment: .leading) {
                    if displayName.isEmpty {
                        Text("Display Name").foregroundColor(.black.opacity(0.6))
                    }
                    TextField("", text: $displayName)
                        .foregroundColor(.black)
                        .focused($isFocused)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Confirm button
                Button(action: onConfirm) {
                    Text("Confirm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // Add extra padding at bottom for keyboard
                Spacer().frame(height: 200)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Preview
struct DisplayNameView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            DisplayNameView(
                displayName: .constant(""),
                onConfirm: {}
            )
        }
    }
}

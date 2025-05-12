//
//  SignUpView.swift
//  FoodMap
//
//  Sign up screen for user authentication
//

import SwiftUI
import Combine

struct SignUpView: View {
    // MARK: - Properties
    @Binding var showLogin: Bool
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var kbHeight: CGFloat = 0
    @State private var showOnboarding = false
    @FocusState private var focus: Field?
    
    // MARK: - Types
    private enum Field {
        case username, email, password
    }

    // How much the speech-bubble climbs up so it "kisses" the penguin
    private let bubbleOverlap: CGFloat = -18
    
    // MARK: - Body
    var body: some View {
        if showOnboarding {
            OnboardingContainer()
        } else {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color.brandRed.ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Always below the notch
                        Spacer(minLength: geo.safeAreaInsets.top)

                        // 🐧 Chef
                        Image("penguin_chef")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170)
                            .padding(.bottom, bubbleOverlap)

                        // 💬 Bubble
                        Text("Welcome to FoodMap! I'm Sakdoumz the Chef Penguin. How can I get to know you?")
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
                            .offset(y: bubbleOverlap)

                        // Gap AFTER bubble
                        Spacer().frame(height: 32 - bubbleOverlap)

                        // Input fields
                        PlaceholderField("Username", text: $username)
                            .focused($focus, equals: .username)
                            .padding(.bottom, 12)
                            
                        PlaceholderField("E-mail", text: $email)
                            .focused($focus, equals: .email)
                            .padding(.bottom, 12)

                        PlaceholderField("Password", text: $password, secure: true)
                            .focused($focus, equals: .password)
                            .padding(.bottom, 16)

                        // Sign Up button
                        PrimaryButton(title: "Sign Up") {
                            // Bypass verification and go straight to onboarding
                            showOnboarding = true
                        }

                        // Divider
                        HStack {
                            divider
                            Text("or sign up with")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            divider
                        }
                        .padding(.vertical, 20)

                        // Google
                        Button {
                            // Bypass verification and go straight to onboarding
                            showOnboarding = true
                        } label: {
                            Image("google_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                        }

                        // Login link
                        Button("Not your first time? Log In") {
                            showLogin = true
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.top, 28)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .onTapGesture { hideKeyboard() }
                    .onReceive(keyboardPublisher) { h in
                        withAnimation(.easeOut(duration: 0.2)) { kbHeight = h }
                    }
                }
                // Reserve bottom safe-area for keyboard
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: kbHeight)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.5))
            .frame(height: 1)
    }

    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(showLogin: .constant(false))
    }
}

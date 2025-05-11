//
//  LoginView.swift
//  FoodMap
//
//  Pixel-perfect Figma implementation – v4
//

import SwiftUI
import Combine

struct LoginView: View {
    // ── State ─────────────────────────────────────────────────────────────
    @State private var email          = ""
    @State private var password       = ""
    @State private var kbHeight: CGFloat = 0
    @FocusState private var focus: Field?
    private enum Field { case email, password }

    // How much the speech-bubble climbs up so it “kisses” the penguin
    private let bubbleOverlap: CGFloat = -18     // tweak ± to taste

    // ── Body ──────────────────────────────────────────────────────────────
    var body: some View {
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
                        // Pull the penguin down a hair so its art-board
                        // doesn’t leave transparent padding above bubble
                        .padding(.bottom, bubbleOverlap)   // negative == up

                    // 💬 Bubble
                    Text("Welcome to FoodMap! I'm Sakdoumz the Chef Penguin. Who am I talking to?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .overlay(                        // black stroke
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(radius: 4, y: 2)
                        )
                        .offset(y: bubbleOverlap)            // climb up

                    // Gap AFTER bubble → keep the rest unchanged
                    Spacer().frame(height: 32 - bubbleOverlap)

                    // 📧 / 🔒
                    PlaceholderField("E-mail", text: $email)
                        .focused($focus, equals: .email)
                        .padding(.bottom, 12)

                    PlaceholderField("Password", text: $password, secure: true)
                        .focused($focus, equals: .password)
                        .padding(.bottom, 8)

                    // 🔑 Forgot password
                    HStack {
                        Spacer()
                        Button("Forgot your password?") { /* TODO */ }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
                    .padding(.bottom, 16)

                    // ▶︎ Log In
                    PrimaryButton(title: "Log In") { /* TODO */ }

                    // Divider
                    HStack {
                        divider
                        Text("or log in with")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        divider
                    }
                    .padding(.vertical, 20)

                    // Google
                    Button { /* TODO */ } label: {
                        Image("google_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    // Sign-up
                    Button("First time here? Sign Up") { /* TODO */ }
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

    // ── Helpers ──────────────────────────────────────────────────────────
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

// MARK: - Reusable sub-components
private struct PlaceholderField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false

    init(_ placeholder: String, text: Binding<String>, secure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.secure = secure
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder).foregroundColor(.black)
            }
            Group {
                secure ? AnyView(SecureField("", text: $text))
                       : AnyView(TextField("", text: $text)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress))
            }
            .foregroundColor(.black)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

private struct PrimaryButton: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black)
                .cornerRadius(12)
        }
    }
}

// MARK: - Constants
extension Color {
    /// #E84936
    static let brandRed = Color(red: 232/255, green: 73/255, blue: 54/255)
}

// MARK: - Hide keyboard helper
#if canImport(UIKit)
extension View {
    fileprivate func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif

//
//  LoginView.swift
//  FoodMap
//
//  Login screen with email verification support
//

import SwiftUI
import Combine
import AuthenticationServices

struct LoginView: View {
    // ── State ─────────────────────────────────────────────────────────────
    @Binding var showLogin: Bool
    var onLogin: ((String) -> Void)?
    
    @State private var rememberCredentials = true
    @State private var kbHeight: CGFloat = 0
    @FocusState private var focus: Field?
    @EnvironmentObject private var viewModel: AuthViewModel
    
    private enum Field { case email, password }

    // How much the speech-bubble climbs up so it "kisses" the penguin
    private let bubbleOverlap: CGFloat = -18     // tweak ± to taste
    
    // ── Initializer ─────────────────────────────────────────────────────────
    init(showLogin: Binding<Bool>, onLogin: ((String) -> Void)? = nil) {
        self._showLogin = showLogin
        self.onLogin = onLogin
    }

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
                        // doesn't leave transparent padding above bubble
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
                    PlaceholderField("E-mail", text: $viewModel.email)
                        .focused($focus, equals: .email)
                        .padding(.bottom, 12)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("emailField")

                    PlaceholderField("Password", text: $viewModel.password, secure: true)
                        .focused($focus, equals: .password)
                        .padding(.bottom, 8)
                        .textContentType(.password)

                    // Save credentials toggle - IMPROVED
                    HStack {
                        Toggle("", isOn: $rememberCredentials)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .white))
                            .padding(4)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .frame(width: 58)
                        
                        Text("Remember me")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                                
                    // 🔑 Forgot password
                    HStack {
                        Spacer()
                        Button("Forgot your password?") {
                            viewModel.forgotPassword()
                        }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // ▶︎ Log In
                    PrimaryButton(title: "Log In") {
                        if rememberCredentials {
                            let _ = (viewModel.authService as? AuthenticationService)?.saveCredentials(email: viewModel.email, password: viewModel.password)
                        }
                        viewModel.login()
                    }
                    .disabled(viewModel.isLoading)

                    // Display error message if there is one - IMPROVED
                    if !viewModel.errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(viewModel.errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 12)
                    }

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
                    Button {
                        viewModel.signInWithGoogle()
                    } label: {
                        Image("google_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    // Sign-up
                    Button("First time here? Sign Up") {
                        showLogin = false
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
        .onChange(of: viewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                // Complete login and navigate to home
                if let user = viewModel.user {
                    onLogin?(user.displayName ?? "User")
                }
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showLogin: .constant(true))
            .environmentObject(AuthViewModel())
    }
}

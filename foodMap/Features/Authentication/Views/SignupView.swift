import SwiftUI
import Combine

struct SignUpView: View {
    // MARK: - Properties
    @Binding var showLogin: Bool
    var onSignUp: ((String) -> Void)?
    
    @State private var email = ""
    @State private var username = "" // New username field
    @State private var password = ""
    @State private var kbHeight: CGFloat = 0
    @FocusState private var focus: Field?
    @EnvironmentObject private var viewModel: AuthViewModel
    
    // MARK: - Types
    private enum Field {
        case email, username, password
    }

    // How much the speech-bubble climbs up so it "kisses" the penguin
    private let bubbleOverlap: CGFloat = -18
    
    // MARK: - Initializer
    init(showLogin: Binding<Bool>, onSignUp: ((String) -> Void)? = nil) {
        self._showLogin = showLogin
        self.onSignUp = onSignUp
    }
    
    // MARK: - Body
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
                        .padding(.bottom, bubbleOverlap)

                    // 💬 Bubble
                    Text("Welcome to FoodMap! I'm Sakdoumz the Chef Penguin. Create your account to get started!")
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
                    PlaceholderField("E-mail", text: $email)
                        .focused($focus, equals: .email)
                        .padding(.bottom, 16)
                        .onChange(of: email) { oldValue, newValue in
                            viewModel.email = newValue
                        }
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    // NEW USERNAME FIELD
                    PlaceholderField("Username (unique)", text: $username)
                        .focused($focus, equals: .username)
                        .padding(.bottom, 16)
                        .onChange(of: username) { oldValue, newValue in
                            viewModel.username = newValue
                        }
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("usernameField")

                    PlaceholderField("Password", text: $password, secure: true)
                        .focused($focus, equals: .password)
                        .padding(.bottom, 24)
                        .textContentType(.newPassword)
                        .onChange(of: password) { oldValue, newValue in
                            viewModel.password = newValue
                        }
                        .accessibilityIdentifier("passwordField")

                    // Sign Up button
                    PrimaryButton(title: "Sign Up") {
                        // Set values in view model
                        viewModel.email = email
                        viewModel.username = username
                        viewModel.password = password
                        
                        // Call the signup method
                        viewModel.signUp()
                        
                        // Wait a bit to ensure Firebase auth completes, then trigger the onSignUp callback
                        // to ensure our navigation flags are set
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if viewModel.isAuthenticated {
                                print("SignUpView: User authenticated, invoking onSignUp callback")
                                onSignUp?(username.isEmpty ? email.components(separatedBy: "@").first ?? "User" : username)
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                    .opacity(viewModel.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1)

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
                        Text("or sign up with")
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
        // Add a direct observer for authentication state changes
        .onChange(of: viewModel.isAuthenticated) { oldValue, newValue in
            if newValue && !oldValue {
                // User just became authenticated (signup completed)
                print("SignUpView: Authentication state changed to true")
                onSignUp?(username.isEmpty ? email.components(separatedBy: "@").first ?? "User" : username)
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

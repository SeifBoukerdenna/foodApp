import SwiftUI
import FirebaseAuth

struct DisplayNameSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var displayName: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.brandRed.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top spacing
                Spacer().frame(height: 100)
                
                // 🐧 Chef Penguin
                Image("penguin_explanation")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
                    .padding(.bottom, -18)
                
                // 💬 Bubble
                Text("Almost done! What should I call you?\n(This will be your displayed name on FoodMap)")
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
                
                // Display Name field
                ZStack(alignment: .leading) {
                    if displayName.isEmpty {
                        Text("Display Name").foregroundColor(.black.opacity(0.6))
                    }
                    TextField("", text: $displayName)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Confirm button
                Button(action: {
                    updateDisplayName()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .disabled(displayName.isEmpty || isLoading)
                .opacity((displayName.isEmpty || isLoading) ? 0.6 : 1)
                
                // Skip button
                Button("Skip for now") {
                    onComplete()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 16)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .padding(.top, 16)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .top)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onAppear {
            // Pre-fill with email username part if we have the email
            if displayName.isEmpty && !authViewModel.email.isEmpty {
                displayName = authViewModel.email.components(separatedBy: "@").first ?? ""
            }
        }
    }
    
    private func updateDisplayName() {
        isLoading = true
        errorMessage = ""
        
        if displayName.isEmpty {
            isLoading = false
            errorMessage = "Please enter a display name"
            return
        }
        
        // Use Firebase SDK directly since we're just updating Auth profile
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            changeRequest.commitChanges { error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("❌ Failed to update display name: \(error.localizedDescription)")
                        errorMessage = "Failed to update display name: \(error.localizedDescription)"
                    } else {
                        print("✅ Display name updated to: \(displayName)")
                        
                        // Update the local user object
                        if var currentUser = authViewModel.user {
                            currentUser.displayName = displayName
                            authViewModel.user = currentUser
                        }
                        
                        // Complete the setup flow
                        onComplete()
                    }
                }
            }
        } else {
            isLoading = false
            errorMessage = "User not found. Please try signing in again."
        }
    }
}

struct DisplayNameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayNameSetupView(onComplete: {})
            .environmentObject(AuthViewModel())
    }
}

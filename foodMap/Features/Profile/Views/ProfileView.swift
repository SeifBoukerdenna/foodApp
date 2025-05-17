import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showConfirmLogout = false
    @State private var showConfirmDelete = false
    @State private var isEditingDisplayName = false
    @State private var newDisplayName = ""
    @State private var showNameUpdateSuccess = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    profileHeader
                    
                    // Email verification section
                    ProfileVerificationSection(viewModel: authViewModel)
                    
                    // Display name update section
                    displayNameUpdateSection
                    
                    // Account section
                    accountSection
                    
                    // Preferences section
                    preferencesSection
                    
                    // Logout button
                    logoutButton
                        .padding(.top, 16)
                    
                    // Delete account button
                    deleteAccountButton
                        .padding(.top, 8)
                    
                    // App info
                    appInfo
                }
                .padding(.bottom, 100) // Add space for tab bar
            }
        }
        .alert(isPresented: $showConfirmLogout) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    authViewModel.signOut()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete Account", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                authViewModel.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
    
    // MARK: - UI Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            ZStack {
                Circle()
                    .fill(Color.brandRed)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // User name
            Text(authViewModel.user?.displayName ?? "User")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                
            // Email
            Text(authViewModel.user?.email ?? "")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 64)
        .padding(.bottom, 20)
    }
    
    private var displayNameUpdateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display Name")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                if isEditingDisplayName {
                    // Editing mode
                    TextField("New Display Name", text: $newDisplayName)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    HStack {
                        Button("Cancel") {
                            isEditingDisplayName = false
                            newDisplayName = ""
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button("Save") {
                            if !newDisplayName.isEmpty {
                                authViewModel.updateDisplayName(newName: newDisplayName)
                                isEditingDisplayName = false
                                showNameUpdateSuccess = true
                                
                                // Automatically hide success message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showNameUpdateSuccess = false
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.brandRed)
                        .cornerRadius(8)
                        .disabled(newDisplayName.isEmpty)
                        .opacity(newDisplayName.isEmpty ? 0.5 : 1)
                    }
                } else {
                    // Display mode
                    HStack {
                        Text(authViewModel.user?.displayName ?? "User")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            newDisplayName = authViewModel.user?.displayName ?? ""
                            isEditingDisplayName = true
                        }) {
                            Text("Edit")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.brandRed)
                                .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Loading indicator or success message
                if authViewModel.isUpdatingProfile {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Updating...")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 14))
                        Spacer()
                    }
                } else if showNameUpdateSuccess {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Display name updated successfully!")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Spacer()
                    }
                } else if !authViewModel.errorMessage.isEmpty {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Account")
                .font(.headline)
                .foregroundColor(.white)
            
            // Account options
            VStack(spacing: 0) {
                profileOption(icon: "person.fill", title: "Personal Information")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.leading, 56)
                
                profileOption(icon: "creditcard", title: "Payment Methods")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.leading, 56)
                
                profileOption(icon: "location.fill", title: "Addresses")
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.white)
            
            // Preferences options
            VStack(spacing: 0) {
                profileOption(icon: "fork.knife", title: "Dietary Preferences")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.leading, 56)
                
                profileOption(icon: "hand.thumbsup.fill", title: "Favorite Cuisines")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.leading, 56)
                
                profileOption(icon: "bell.fill", title: "Notifications")
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
    
    private var logoutButton: some View {
        Button(action: {
            showConfirmLogout = true
        }) {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                    Text("Log Out")
                }
                .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(Color.brandRed)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var deleteAccountButton: some View {
        Button(action: {
            showConfirmDelete = true
        }) {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                }
                .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .opacity(authViewModel.isDeletingAccount ? 0.5 : 1)
        .disabled(authViewModel.isDeletingAccount)
        .overlay(
            Group {
                if authViewModel.isDeletingAccount {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Deleting...")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }
            }
        )
    }
    
    private var appInfo: some View {
        VStack(spacing: 4) {
            Text("FoodMap v1.0.0")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text("© 2025 Sakdoumz Chef Penguin Inc.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    // Helper function for profile options
    private func profileOption(icon: String, title: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.brandRed)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AuthViewModel()
        viewModel.user = User(
            id: "123",
            email: "user@example.com",
            displayName: "FoodLover",
            isEmailVerified: false
        )
        
        return ProfileView()
            .environmentObject(viewModel)
            .preferredColorScheme(.dark)
    }
}

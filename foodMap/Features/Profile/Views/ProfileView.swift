import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showConfirmLogout = false
    
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
                    
                    // Account section
                    accountSection
                    
                    // Preferences section
                    preferencesSection
                    
                    // Logout button
                    logoutButton
                        .padding(.top, 16)
                    
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

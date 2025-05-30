import SwiftUI

struct MainContainer: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    let displayName: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            TabContent(selectedTab: selectedTab, displayName: displayName)
                .padding(.bottom, 83) // Space for custom tab bar
            
            // Custom tab bar at bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Check email verification status when the view appears
            authViewModel.checkEmailVerificationStatus()
        }
    }
}

struct TabContent: View {
    let selectedTab: Int
    let displayName: String
    
    var body: some View {
        ZStack {
            switch selectedTab {
            case 0:
                HomeView(displayName: displayName)
            case 1:
                FriendsPlaceholder()
            case 2:
                MapPlaceholder()
            case 3:
                CartPlaceholder()
            case 4:
                ProfileView()
            default:
                HomeView(displayName: displayName)
            }
        }
    }
}

// Placeholder views for tabs that aren't fully implemented yet
struct FriendsPlaceholder: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.brandRed)
                
                Text("Friends Feature")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}


struct MapPlaceholder: View {
    var body: some View {
        MapView() // Use the actual MapView instead of placeholder
    }
}

struct CartPlaceholder: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.brandRed)
                
                Text("Shopping Cart")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct MainContainer_Previews: PreviewProvider {
    static var previews: some View {
        MainContainer(displayName: "FoodLover")
            .environmentObject(AuthViewModel())
    }
}

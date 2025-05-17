import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    let displayName: String
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(displayName: displayName)
                .tag(0)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            Text("Friends")
                .tag(1)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            
            Text("Map")
                .tag(2)
                .tabItem {
                    Image(systemName: "mappin.circle.fill")
                    Text("Map")
                }
            
            Text("Cart")
                .tag(3)
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Cart")
                }
            
            ProfileView()
                .tag(4)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(.brandRed)
        .onAppear {
            // Check email verification status when tab view appears
            authViewModel.checkEmailVerificationStatus()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(displayName: "FoodLover")
            .environmentObject(AuthViewModel())
    }
}

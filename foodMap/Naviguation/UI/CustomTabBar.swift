import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // Regular tabs
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    if index != 2 { // Skip center tab
                        TabButton(
                            icon: getIcon(for: index),
                            title: getTitle(for: index),
                            isSelected: selectedTab == index,
                            action: { selectedTab = index }
                        )
                    } else {
                        // Empty space for center button
                        Spacer()
                            .frame(width: UIScreen.main.bounds.width / 5)
                    }
                }
            }
            .frame(height: 49)
            .padding(.top, 8)
            .padding(.bottom, 28) // Safe area padding
            .background(
                Color.brandRed
                    .cornerRadius(25, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
            )
            
            // Center tab button (Map) - on top of others
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.brandRed)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .offset(y: -15)
                .onTapGesture {
                    selectedTab = 2
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width / 5)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func getIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "person.2.fill"
        case 3: return "cart.fill"
        case 4: return "person.crop.circle.fill"
        default: return ""
        }
    }
    
    private func getTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Friends"
        case 2: return "Map"
        case 3: return "Cart"
        case 4: return "Profile"
        default: return ""
        }
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
    }
}


struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0))
        }
        .background(Color.black.opacity(0.8))
    }
}

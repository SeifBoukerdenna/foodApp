//
//  HomeView.swift
//  FoodMap
//
//  Basic home page that will be expanded later
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    let displayName: String
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome to FoodMap")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Hey there, \(displayName)!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Small penguin avatar
                Image("penguin_chef")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
            .padding()
            
            // Empty state content
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "map")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Your food adventure awaits!")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("We'll be adding delicious locations soon")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(displayName: "FoodLover")
    }
}

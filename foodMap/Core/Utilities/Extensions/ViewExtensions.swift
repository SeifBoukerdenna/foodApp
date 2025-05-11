import SwiftUI

extension View {
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(8)
            .padding(.horizontal)
    }
    
    func customTextFieldStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

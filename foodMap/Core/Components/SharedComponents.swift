//
//  SharedComponents.swift
//  FoodMap
//
//  Reusable components shared across the app
//

import SwiftUI

// MARK: - Placeholder Field
struct PlaceholderField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false
    
    init(_ placeholder: String, text: Binding<String>, secure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.secure = secure
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder).foregroundColor(.black.opacity(0.6))
            }
            Group {
                secure ? AnyView(SecureField("", text: $text))
                       : AnyView(TextField("", text: $text)
                            .autocapitalization(.none)
                            .keyboardType(placeholder == "E-mail" ? .emailAddress : .default)
                            .textContentType(placeholder == "E-mail" ? .emailAddress :
                                            placeholder == "Username" ? .username : .none))
            }
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
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black)
                .cornerRadius(12)
        }
    }
}

// MARK: - Speech Bubble
struct SpeechBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
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
    }
}

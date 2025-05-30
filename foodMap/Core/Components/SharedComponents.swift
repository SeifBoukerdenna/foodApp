//
//  SharedComponents.swift
//  FoodMap
//
//  Reusable components shared across the app
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .padding(.top, 8)
    }
}

struct ErrorMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            ErrorMessageView(message: "Username is already taken. Please choose a different username.")
                .padding()
        }
    }
}


struct PlaceholderField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false
    var contentType: UITextContentType?
    
    init(_ placeholder: String, text: Binding<String>, secure: Bool = false, contentType: UITextContentType? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.secure = secure
        self.contentType = contentType
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder).foregroundColor(.black.opacity(0.6))
            }
            Group {
                if secure {
                    SecureField("", text: $text)
                        .textContentType(contentType)
                } else {
                    TextField("", text: $text)
                        .textContentType(contentType)
                        .autocapitalization(.none)
                        .keyboardType(placeholder == "E-mail" ? .emailAddress : .default)
                }
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

struct PlaceholderField_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            PlaceholderField("Email", text: .constant(""))
                .padding()
        }
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

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.brandRed.ignoresSafeArea()
            PrimaryButton(title: "Test Button", action: {})
                .padding()
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

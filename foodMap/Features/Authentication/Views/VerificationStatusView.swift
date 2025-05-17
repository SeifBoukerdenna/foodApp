//
//  VerificationStatusView.swift
//  FoodMap
//
//  Verification status banner for the app
//

import SwiftUI

struct VerificationStatusView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        if !viewModel.isEmailVerified {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 18))
                    
                    // Status text
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email not verified")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Please check your inbox and verify your email address")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Resend button
                    if viewModel.isCheckingEmailVerification {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            viewModel.sendVerificationEmail()
                            viewModel.checkEmailVerificationStatus()
                        }) {
                            Text("Resend")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.brandRed)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
                
                // Refresh button
                Button(action: {
                    viewModel.checkEmailVerificationStatus()
                }) {
                    HStack(spacing: 4) {
                        Text("Refresh verification status")
                            .font(.system(size: 12))
                        
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                }
            }
        }
    }
}

struct VerificationStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AuthViewModel()
        viewModel.isEmailVerified = false
        
        return ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            
            VerificationStatusView(viewModel: viewModel)
                .previewLayout(.sizeThatFits)
        }
    }
}

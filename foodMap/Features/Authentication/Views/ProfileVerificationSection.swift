//
//  ProfileVerificationSection.swift
//  FoodMap
//
//  Component for the profile screen to show verification status
//

import SwiftUI

struct ProfileVerificationSection: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Email Verification")
                .font(.headline)
                .foregroundColor(.white)
            
            // Status card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Status icon
                    Image(systemName: viewModel.isEmailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.isEmailVerified ? .green : .yellow)
                    
                    // Status text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.isEmailVerified ? "Email Verified" : "Email Not Verified")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let user = viewModel.user, let email = user.email.isEmpty ? nil : user.email {
                            Text(email)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Verification action
                    if !viewModel.isEmailVerified {
                        Button(action: {
                            viewModel.sendVerificationEmail()
                        }) {
                            Text("Verify")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.brandRed)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                
                // Information text or verification instructions
                if viewModel.isEmailVerified {
                    Text("Your email has been verified. You have full access to all features.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Please verify your email to access all features:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Steps to verify
                        VStack(alignment: .leading, spacing: 4) {
                            verificationStep(number: 1, text: "Click the 'Verify' button to receive a verification email")
                            verificationStep(number: 2, text: "Open the email and click the verification link")
                            verificationStep(number: 3, text: "Return here and click 'Check Status'")
                        }
                        
                        // Check status button
                        Button(action: {
                            viewModel.checkEmailVerificationStatus()
                        }) {
                            HStack {
                                Text("Check Status")
                                
                                if viewModel.isCheckingEmailVerification {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isCheckingEmailVerification)
                        .padding(.top, 8)
                    }
                }
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding(16)
        .onAppear {
            // Check verification status when the view appears
            viewModel.checkEmailVerificationStatus()
        }
    }
    
    private func verificationStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

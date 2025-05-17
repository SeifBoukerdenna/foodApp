//
//  EmailVerificationView.swift
//  FoodMap
//
//  Screen shown after signup to inform about verification
//

import SwiftUI

struct EmailVerificationView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onContinue: () -> Void
    
    // Timer for auto-refreshing verification status
    @State private var timeRemaining = 30
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header
            ZStack {
                Color.brandRed.ignoresSafeArea(edges: .top)
                
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    
                    // Penguin with verification icon
                    ZStack(alignment: .topTrailing) {
                        Image("penguin_chef")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                        
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.brandRed)
                                    .frame(width: 60, height: 60)
                            )
                            .offset(x: 10, y: -5)
                    }
                    
                    Text("Verify Your Email")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("We've sent a verification link to:\n\(viewModel.email)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .frame(height: 320)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        instructionRow(number: "1", text: "Check your inbox for the verification email")
                        instructionRow(number: "2", text: "Click the verification link in the email")
                        instructionRow(number: "3", text: "Return here after verifying")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    
                    // Verification status
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.isEmailVerified ? "checkmark.circle.fill" : "clock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.isEmailVerified ? .green : .yellow)
                            
                            Text(viewModel.isEmailVerified ? "Email Verified" : "Awaiting Verification")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(viewModel.isEmailVerified ? .green : .yellow)
                        }
                        
                        if !viewModel.isEmailVerified {
                            Text("Auto-checking in: \(timeRemaining)s")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Refresh button
                        Button(action: {
                            viewModel.checkEmailVerificationStatus()
                            timeRemaining = 30 // Reset timer
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Check Verification Status")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isCheckingEmailVerification)
                        
                        // Resend button
                        Button(action: {
                            viewModel.sendVerificationEmail()
                        }) {
                            HStack {
                                Image(systemName: "envelope.arrow.triangle.branch")
                                Text("Resend Verification Email")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Continue button
                        Button(action: onContinue) {
                            Text(viewModel.isEmailVerified ? "Continue to App" : "Continue Without Verifying")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.isEmailVerified ? Color.brandRed : Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        if !viewModel.isEmailVerified {
                            Text("You can continue without verifying, but some features may be limited")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 && !viewModel.isEmailVerified {
                timeRemaining -= 1
                
                // Auto-check verification status when timer reaches certain intervals
                if timeRemaining % 10 == 0 || timeRemaining == 0 {
                    viewModel.checkEmailVerificationStatus()
                }
            }
            
            // Stop timer if verified
            if viewModel.isEmailVerified {
                timeRemaining = 0
            }
        }
        .onAppear {
            // Check status when view appears
            viewModel.checkEmailVerificationStatus()
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.brandRed)
                .cornerRadius(16)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AuthViewModel()
        viewModel.email = "user@example.com"
        
        return EmailVerificationView(viewModel: viewModel, onContinue: {})
    }
}

import SwiftUI

struct ActiveMemberPaymentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var promoCode: String = ""
    @State private var showingPromoCode = false
    @State private var promoCodeApplied = false
    @State private var promoCodeError: String?
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String?
    
    // Payment fields
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    private let monthlyPrice = 5.00
    private let secureKeyManager = SecureKeyManager.shared
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Back Button
                HStack {
                    Button(action: {
                        onSkip() // Go back if they cancel
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Complete Your Payment")
                        .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer for balance
                    Button(action: {}) {
                        Text("")
                            .frame(width: 60)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 30 : 20)
                
                // Subtitle
                Text("Secure payment powered by Stripe")
                    .font(.system(size: DeviceSize.bodyFontSize))
                    .foregroundColor(.gray)
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: DeviceSize.isPad ? 24 : 20) {
                        // Cancel Anytime Banner
                        HStack {
                            Text("Cancel anytime. No long-term commitment.")
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(DeviceSize.isPad ? 20 : 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.getActiveRed, lineWidth: 1)
                        )
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 30 : 24)
                        
                        // Active Membership Card
                        VStack(spacing: 16) {
                            Text("Active Membership")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("$\(String(format: "%.0f", monthlyPrice))/month")
                                .font(.system(size: DeviceSize.isPad ? 48 : 40, weight: .bold))
                                .foregroundColor(.getActiveRed)
                            
                            Text("Cancel anytime. No long-term commitment.")
                                .font(.system(size: DeviceSize.captionFontSize))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DeviceSize.isPad ? 24 : 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.getActiveRed, lineWidth: 1)
                        )
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // What you'll get section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What you'll get:")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(icon: "checkmark.circle.fill", text: "Create unlimited events", iconColor: .green)
                                FeatureRow(icon: "checkmark.circle.fill", text: "Access event analytics", iconColor: .green)
                                FeatureRow(icon: "checkmark.circle.fill", text: "Priority event visibility", iconColor: .green)
                                FeatureRow(icon: "checkmark.circle.fill", text: "Exclusive member badge", iconColor: .green)
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, 8)
                        
                        // Payment Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Payment Information")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            // Card Number
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Card Number")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("*")
                                        .foregroundColor(.getActiveRed)
                                }
                                
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(.gray)
                                    TextField("1234 5678 9012 3456", text: $cardNumber)
                                        .font(.system(size: DeviceSize.bodyFontSize))
                                        .foregroundColor(.white)
                                        .keyboardType(.numberPad)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            // Expiry Date and CVV
                            HStack(spacing: 12) {
                                // Expiry Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Expiry Date")
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("*")
                                            .foregroundColor(.getActiveRed)
                                    }
                                    
                                    TextField("MM/YY", text: $expiryDate)
                                        .font(.system(size: DeviceSize.bodyFontSize))
                                        .foregroundColor(.white)
                                        .keyboardType(.numberPad)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                }
                                
                                // CVV
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("CVV")
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("*")
                                            .foregroundColor(.getActiveRed)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "lock")
                                            .foregroundColor(.gray)
                                        TextField("123", text: $cvv)
                                            .font(.system(size: DeviceSize.bodyFontSize))
                                            .foregroundColor(.white)
                                            .keyboardType(.numberPad)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            // Cardholder Name
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Cardholder Name")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("*")
                                        .foregroundColor(.getActiveRed)
                                }
                                
                                TextField("John Doe", text: $cardholderName)
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                        }
                        .padding(.top, 20)
                        
                        // Promo Code Section
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    showingPromoCode.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.getActiveRed)
                                    
                                    Text(promoCodeApplied ? "Promo code applied!" : "Have a promo code?")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(promoCodeApplied ? .getActiveRed : .white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showingPromoCode ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            if showingPromoCode && !promoCodeApplied {
                                HStack(spacing: 12) {
                                    TextField("Enter promo code", text: $promoCode)
                                        .font(.system(size: DeviceSize.bodyFontSize))
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    
                                    Button(action: {
                                        applyPromoCode()
                                    }) {
                                        Text("Apply")
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.getActiveRed)
                                            .cornerRadius(12)
                                    }
                                }
                                
                                if let error = promoCodeError {
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.getActiveRed)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            if promoCodeApplied {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Promo code applied successfully!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                    }
                }
                
                // Payment Button
                Button(action: {
                    processPayment()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(promoCodeApplied ? "Continue (Free Access)" : "Pay $\(String(format: "%.0f", monthlyPrice))/month")
                                .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: DeviceSize.isPad ? 60 : 55)
                    .background(Color.getActiveRed)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 16)
                .padding(.bottom, DeviceSize.isPad ? 30 : 20)
                
                // Security Text
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("Your payment information is secure and encrypted")
                        .font(.system(size: DeviceSize.captionFontSize))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, DeviceSize.isPad ? 20 : 16)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Payment processing failed")
        }
    }
    
    private func applyPromoCode() {
        promoCodeError = nil
        let trimmedCode = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Verify promo code using secure hash comparison
        if secureKeyManager.verifyPromoCode(trimmedCode) {
            promoCodeApplied = true
            promoCodeError = nil
            showingPromoCode = false
        } else {
            promoCodeError = "Invalid promo code. Please try again."
        }
    }
    
    private func processPayment() {
        isLoading = true
        
        // Simulate payment processing
        // In production, integrate with payment provider (Stripe, Apple Pay, etc.)
        Task {
            // Add delay to simulate payment processing
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                // Update user payment status
                if var user = authManager.currentUser {
                    user.isPaymentActive = true
                    user.subscriptionStatus = promoCodeApplied ? "promo" : "active"
                    user.subscriptionStartDate = Date()
                    
                    // Update user in Firebase
                    authManager.updateUser(user) { success in
                        isLoading = false
                        if success {
                            onComplete()
                        } else {
                            errorMessage = "Failed to process payment. Please try again."
                            showingError = true
                        }
                    }
                } else {
                    isLoading = false
                    errorMessage = "User not found"
                    showingError = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    var iconColor: Color = .getActiveRed
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: DeviceSize.bodyFontSize))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}


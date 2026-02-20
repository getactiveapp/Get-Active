import SwiftUI

struct ActiveMemberApplicationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isInvolvedInOrgs: Bool = false
    @State private var classification: String = ""
    @State private var fullName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    let onComplete: () -> Void
    
    let classifications = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate Student", "Alumni", "Faculty/Staff"]
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Active Member Application")
                        .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 30 : 20)
                
                // Subtitle
                Text("Please complete this application to verify your Active Member status")
                    .font(.system(size: DeviceSize.bodyFontSize))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: DeviceSize.isPad ? 24 : 20) {
                        // Question 1: Full Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What is your name?")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter your full name", text: $fullName)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        // Question 2: Classification
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What is your classification?")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Menu {
                                ForEach(classifications, id: \.self) { classificationOption in
                                    Button(action: {
                                        classification = classificationOption
                                    }) {
                                        Text(classificationOption)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(classification.isEmpty ? "Select your classification" : classification)
                                        .font(.system(size: DeviceSize.bodyFontSize))
                                        .foregroundColor(classification.isEmpty ? .gray : .white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Question 3: Involved in Orgs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Are you involved in any organizations?")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    isInvolvedInOrgs = true
                                }) {
                                    HStack {
                                        Image(systemName: isInvolvedInOrgs ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isInvolvedInOrgs ? .getActiveRed : .gray)
                                        
                                        Text("Yes")
                                            .font(.system(size: DeviceSize.bodyFontSize))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                    .background(isInvolvedInOrgs ? Color.getActiveRed.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isInvolvedInOrgs ? Color.getActiveRed : Color.clear, lineWidth: 2)
                                    )
                                }
                                
                                Button(action: {
                                    isInvolvedInOrgs = false
                                }) {
                                    HStack {
                                        Image(systemName: !isInvolvedInOrgs ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(!isInvolvedInOrgs ? .getActiveRed : .gray)
                                        
                                        Text("No")
                                            .font(.system(size: DeviceSize.bodyFontSize))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                    .background(!isInvolvedInOrgs ? Color.getActiveRed.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(!isInvolvedInOrgs ? Color.getActiveRed : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 30 : 24)
                }
                
                // Continue Button
                Button(action: {
                    submitApplication()
                }) {
                    Text("Continue to Payment")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 55)
                        .background(isFormValid ? Color.getActiveRed : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 16)
                .padding(.bottom, DeviceSize.isPad ? 30 : 20)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Please fill in all required fields")
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && !classification.isEmpty
    }
    
    private func submitApplication() {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        isLoading = true
        
        // Save application data to user
        if var user = authManager.currentUser {
            // Update user with application data (store as String values for Firestore)
            user.applicationData = [
                "fullName": fullName,
                "classification": classification,
                "isInvolvedInOrgs": "\(isInvolvedInOrgs)"
            ]
            
            // Update user in Firebase
            authManager.updateUser(user) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.onComplete()
                    } else {
                        self.errorMessage = "Failed to save application. Please try again."
                        self.showingError = true
                    }
                }
            }
        } else {
            isLoading = false
            errorMessage = "User not found"
            showingError = true
        }
    }
}


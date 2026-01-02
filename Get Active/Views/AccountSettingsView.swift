import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var bio: String = ""
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Account Settings")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 25) {
                        // Profile Picture Section
                        VStack(spacing: 15) {
                            Text("Profile Picture")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Text(String((authManager.currentUser?.name.prefix(1) ?? "U")))
                                                .font(.system(size: 60, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                Circle()
                                    .stroke(Color.getActiveRed, lineWidth: 2)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                Text("Change Profile Picture")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.getActiveRed, lineWidth: 1)
                                    )
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let newItem = newItem {
                                        if let data = try? await newItem.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            await MainActor.run {
                                                profileImage = image
                                                // In a real app, you would save this to the user's profile
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Edit Your Bio")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextEditor(text: $bio)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                            
                            Text("Tell people about yourself")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: {
                            saveProfileChanges()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(Color.getActiveRed)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Delete Account Button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete Account")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                authManager.deleteAccount { success in
                    if success {
                        // Account deleted, user will be logged out automatically
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
        }
        .onAppear {
            // Load current bio and profile image
            bio = authManager.currentUser?.bio ?? ""
            
            // Load profile image if available
            if let imageName = authManager.currentUser?.profileImageName {
                Task {
                    if let image = await loadProfileImage(from: imageName) {
                        await MainActor.run {
                            profileImage = image
                        }
                    }
                }
            }
        }
    }
    
    private func loadProfileImage(from fileName: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fileManager = FileManager.default
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsPath.appendingPathComponent(fileName)
                
                do {
                    let imageData = try Data(contentsOf: filePath)
                    if let image = UIImage(data: imageData) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func saveProfileChanges() {
        guard var user = authManager.currentUser else { return }
        
        // Save profile image if changed
        if let image = profileImage {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // Delete old profile image if exists
            if let oldImageName = user.profileImageName {
                let oldFilePath = documentsPath.appendingPathComponent(oldImageName)
                try? fileManager.removeItem(at: oldFilePath)
            }
            
            // Save new profile image
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let fileName = "profile_\(user.id).jpg"
                let filePath = documentsPath.appendingPathComponent(fileName)
                
                do {
                    try imageData.write(to: filePath)
                    user.profileImageName = fileName
                } catch {
                    print("Error saving profile image: \(error)")
                }
            }
        }
        
        // Update bio
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save user changes using the updateUser method
        authManager.updateUser(user)
        
        dismiss()
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AuthenticationManager())
}


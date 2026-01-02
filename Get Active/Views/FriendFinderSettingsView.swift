import SwiftUI
import PhotosUI

struct FriendFinderSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var friendFinderImage: UIImage?
    @State private var description: String = ""
    @State private var characterCount: Int = 0
    private let maxDescriptionLength = 200
    
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
                        
                        Text("Friend Finder Profile")
                            .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Image(systemName: "chevron.left")
                            .font(.system(size: DeviceSize.isPad ? 24 : 20))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 20 : 10)
                    .padding(.bottom, DeviceSize.isPad ? 20 : 10)
                    
                    VStack(spacing: DeviceSize.isPad ? 30 : 25) {
                        // Image Section
                        VStack(spacing: DeviceSize.isPad ? 20 : 15) {
                            Text("Profile Image")
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                if let friendFinderImage = friendFinderImage {
                                    Image(uiImage: friendFinderImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo")
                                                    .font(.system(size: DeviceSize.isPad ? 50 : 40))
                                                    .foregroundColor(.gray)
                                                Text("No image selected")
                                                    .font(.system(size: DeviceSize.bodyFontSize))
                                                    .foregroundColor(.gray)
                                            }
                                        )
                                }
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.getActiveRed, lineWidth: 2)
                            }
                            .frame(width: DeviceSize.screenWidth - (DeviceSize.horizontalPadding * 2), height: (DeviceSize.screenWidth - (DeviceSize.horizontalPadding * 2)) * 0.75)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                Text(friendFinderImage == nil ? "Select Image" : "Change Image")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DeviceSize.buttonHeight)
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
                                                friendFinderImage = image
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if friendFinderImage != nil {
                                Button(action: {
                                    friendFinderImage = nil
                                    selectedPhotoItem = nil
                                }) {
                                    Text("Remove Image")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.getActiveRed)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: DeviceSize.buttonHeight)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.vertical, DeviceSize.isPad ? 25 : 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: DeviceSize.isPad ? 15 : 12) {
                            HStack {
                                Text("Personal Description")
                                    .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(characterCount)/\(maxDescriptionLength)")
                                    .font(.system(size: DeviceSize.captionFontSize))
                                    .foregroundColor(characterCount > maxDescriptionLength ? .getActiveRed : .gray)
                            }
                            
                            TextEditor(text: $description)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .frame(height: DeviceSize.isPad ? 150 : 120)
                                .padding(DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                                .onChange(of: description) { _, newValue in
                                    characterCount = newValue.count
                                    if characterCount > maxDescriptionLength {
                                        description = String(newValue.prefix(maxDescriptionLength))
                                        characterCount = maxDescriptionLength
                                    }
                                }
                            
                            Text("Write a short description about yourself that will appear in Friend Finder")
                                .font(.system(size: DeviceSize.captionFontSize))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.vertical, DeviceSize.isPad ? 25 : 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // Save Button
                        Button(action: {
                            saveFriendFinderProfile()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DeviceSize.buttonHeight)
                                .background(Color.getActiveRed)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 20 : 10)
                    }
                    .padding(.vertical, DeviceSize.isPad ? 30 : 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Load current friend finder profile
            description = authManager.currentUser?.friendFinderDescription ?? ""
            characterCount = description.count
            
            // Load friend finder image if available
            if let imageName = authManager.currentUser?.friendFinderImageName {
                Task {
                    if let image = await loadFriendFinderImage(from: imageName) {
                        await MainActor.run {
                            friendFinderImage = image
                        }
                    }
                }
            }
        }
    }
    
    private func loadFriendFinderImage(from fileName: String) async -> UIImage? {
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
    
    private func saveFriendFinderProfile() {
        guard var user = authManager.currentUser else { return }
        
        // Save friend finder image if changed
        if let image = friendFinderImage {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // Delete old friend finder image if exists
            if let oldImageName = user.friendFinderImageName {
                let oldFilePath = documentsPath.appendingPathComponent(oldImageName)
                try? fileManager.removeItem(at: oldFilePath)
            }
            
            // Save new friend finder image
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let fileName = "friendfinder_\(user.id).jpg"
                let filePath = documentsPath.appendingPathComponent(fileName)
                
                do {
                    try imageData.write(to: filePath)
                    user.friendFinderImageName = fileName
                } catch {
                    print("Error saving friend finder image: \(error)")
                }
            }
        } else {
            // Remove image if cleared
            if let oldImageName = user.friendFinderImageName {
                let fileManager = FileManager.default
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let oldFilePath = documentsPath.appendingPathComponent(oldImageName)
                try? fileManager.removeItem(at: oldFilePath)
                user.friendFinderImageName = nil
            }
        }
        
        // Update description
        user.friendFinderDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save user changes
        authManager.updateUser(user)
        
        dismiss()
    }
}

#Preview {
    FriendFinderSettingsView()
        .environmentObject(AuthenticationManager())
}

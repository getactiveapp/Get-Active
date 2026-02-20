import SwiftUI
import PhotosUI
import UIKit

struct EventPostingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var eventManager: EventManager
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var location = ""
    @State private var selectedCategory: EventCategory = .other
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Create Event")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        createEvent()
                    }) {
                        Text("Post")
                            .foregroundColor(.getActiveRed)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter event title", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter description", text: $description, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(5...10)
                        }
                        
                        // Images Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add Images/Flyers")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Add flyers, photos, or important images for your event")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            // Image Picker Button
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 18))
                                    Text("Select from Camera Roll")
                                        .font(.system(size: 16, weight: .medium))
                                }
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
                            .onChange(of: selectedPhotoItems) { oldItems, newItems in
                                Task {
                                    selectedImages.removeAll()
                                    for item in newItems {
                                        do {
                                            if let data = try await item.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                selectedImages.append(image)
                                            }
                                        } catch {
                                            print("Error loading image: \(error)")
                                        }
                                    }
                                }
                            }
                            
                            // Display Selected Images
                            if !selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                    if index < selectedPhotoItems.count {
                                                        selectedPhotoItems.remove(at: index)
                                                    }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                        .background(Color.getActiveRed)
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // Date and Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                        }
                        
                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Time")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("3:00 PM", text: $startTime)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Time")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("7:00 PM", text: $endTime)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter location", text: $location)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(EventCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .colorScheme(.dark)
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button(action: {
                                    addTag()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.getActiveRed)
                                }
                            }
                            
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(tags, id: \.self) { tag in
                                            HStack {
                                                Text(tag)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                
                                                Button(action: {
                                                    tags.removeAll { $0 == tag }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
            }
        }
    }
    
    private func addTag() {
        guard !newTag.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        tags.append(newTag)
        newTag = ""
    }
    
    private func getCategoryStyle(_ category: EventCategory) -> (backgroundColor: String, iconName: String) {
        switch category {
        case .technology:
            return ("blue", "laptopcomputer")
        case .career:
            return ("orange", "briefcase.fill")
        case .party:
            return ("green", "music.note")
        case .academic:
            return ("purple", "book.closed.fill")
        case .vendor:
            return ("brown", "cart.fill")
        case .prayer:
            return ("indigo", "hands.sparkles.fill")
        case .club:
            return ("teal", "person.3.fill")
        case .mentalHealth:
            return ("green", "heart.text.square.fill")
        case .other:
            return ("red", "calendar")
        }
    }
    
    private func createEvent() {
        guard !title.isEmpty, !location.isEmpty else { return }
        
        // Save images to documents directory and get file names
        var imageNames: [String] = []
        if !selectedImages.isEmpty {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            for (index, image) in selectedImages.enumerated() {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let fileName = "\(UUID().uuidString)_\(index).jpg"
                    let filePath = documentsPath.appendingPathComponent(fileName)
                    
                    do {
                        try imageData.write(to: filePath)
                        imageNames.append(fileName)
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            }
        }
        
        // Determine backgroundColor and iconName based on category
        let (backgroundColor, iconName) = getCategoryStyle(selectedCategory)
        
        // Normalize the selected date to start of day to ensure proper date comparison
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        
        let newEvent = Event(
            title: title,
            description: description,
            date: normalizedDate,
            startTime: startTime.isEmpty ? "TBD" : startTime,
            endTime: endTime.isEmpty ? "TBD" : endTime,
            location: location,
            category: selectedCategory,
            tags: tags,
            imageName: imageNames.first, // Store first image name for backward compatibility
            backgroundColor: backgroundColor,
            iconName: iconName,
            createdBy: authManager.currentUser?.id ?? "",
            isFeatured: false,
            customImages: imageNames // Store all image names
        )
        
        // Upload images to Firebase Storage if using Firebase
        if eventManager.useFirebase {
            uploadEventImagesAndCreateEvent(newEvent, imageNames: imageNames)
            print("✅ This worked.")
        } else {
            // Local storage
            print("❌ This did not worked.")
            eventManager.events.append(newEvent)
            DispatchQueue.main.async {
                eventManager.objectWillChange.send()
            }
            dismiss()
        }
    }
    
    private func uploadEventImagesAndCreateEvent(_ event: Event, imageNames: [String]) {
        guard !imageNames.isEmpty else {
            // No images, just create event
            createEventInFirebase(event)
            return
        }
        
        // Upload images to Firebase Storage
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(documentsPath)
        var uploadedImageUrls: [String] = []
        var uploadCount = 0
        
        for imageName in imageNames {
            let filePath = documentsPath.appendingPathComponent(imageName)
            
            guard let imageData = try? Data(contentsOf: filePath) else {
                continue
            }
            
            let storagePath = "events/\(event.id)/\(imageName)"
            FirebaseService.shared.uploadImage(imageData, path: storagePath) { result in
                uploadCount += 1
                
                switch result {
                case .success(let url):
                    uploadedImageUrls.append(url)
                    print("Something uploaded.")
                case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                }
                
                // When all images are processed, create event
                if uploadCount == imageNames.count {
                    var eventWithImages = event
                    eventWithImages.customImages = uploadedImageUrls
                    self.createEventInFirebase(eventWithImages)
                }
            }
        }
    }
    
    private func createEventInFirebase(_ event: Event) {
        FirebaseService.shared.createEvent(event) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let eventId):
                    print("✅ Event created in Firebase with ID: \(eventId)")
                    dismiss()
                case .failure(let error):
                    print("❌ Error creating event: \(error.localizedDescription)")
                    // Show error to user
                    // For now, just dismiss - in production, show alert
                    dismiss()
                }
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

#Preview {
    EventPostingView(eventManager: EventManager())
        .environmentObject(AuthenticationManager())
}


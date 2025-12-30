import Foundation
import SwiftUI

struct FeatureFlags: Codable, Equatable {
    var nextDoorEnabled: Bool
    var friendFinderEnabled: Bool
    var mapEnabled: Bool
    var favoritesEnabled: Bool
    
    // Add more feature flags as needed
    var analyticsEnabled: Bool
    var chatBotEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case nextDoorEnabled = "next_door_enabled"
        case friendFinderEnabled = "friend_finder_enabled"
        case mapEnabled = "map_enabled"
        case favoritesEnabled = "favorites_enabled"
        case analyticsEnabled = "analytics_enabled"
        case chatBotEnabled = "chatbot_enabled"
    }
    
    // Default flags (fallback if remote config fails)
    static let `default` = FeatureFlags(
        nextDoorEnabled: false, // Set to false to hide Next Door by default
        friendFinderEnabled: true,
        mapEnabled: true,
        favoritesEnabled: true,
        analyticsEnabled: true,
        chatBotEnabled: true
    )
}

class FeatureFlagsManager: ObservableObject {
    @Published var flags: FeatureFlags = .default
    @Published var isLoading: Bool = false
    @Published var lastUpdate: Date?
    
    // GitHub raw file URL - Configure in FeatureFlagsConfig.swift
    private var remoteConfigURL: String {
        // Use the config file for easy setup
        let url = FeatureFlagsConfig.remoteConfigURL
        
        // If not configured, fall back to placeholder (will fail gracefully)
        if url.contains("YOUR_USERNAME") || url.contains("YOUR_REPO") {
            // Return empty string to skip remote loading and use defaults
            return ""
        }
        
        return url
    }
    
    // Local config file name
    private let localConfigFileName = "feature-flags.json"
    
    init() {
        loadFlags()
    }
    
    func loadFlags() {
        isLoading = true
        
        // Try to load from remote (GitHub) first
        loadFromRemote { [weak self] success in
            if !success {
                // Fallback to local config if remote fails
                self?.loadFromLocal()
            }
            DispatchQueue.main.async {
                self?.isLoading = false
            }
        }
    }
    
    private func loadFromRemote(completion: @escaping (Bool) -> Void) {
        let configURL = remoteConfigURL
        
        // Skip remote loading if not configured
        guard !configURL.isEmpty, let url = URL(string: configURL) else {
            print("⚠️ Feature Flags: Remote URL not configured, using defaults")
            completion(false)
            return
        }
        
        print("🔄 Feature Flags: Loading from GitHub...")
        print("📍 URL: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Feature Flags: Network error - \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Feature Flags: Invalid response")
                completion(false)
                return
            }
            
            print("📡 Feature Flags: HTTP Status \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200,
                  let data = data else {
                print("❌ Feature Flags: Failed to load (Status: \(httpResponse.statusCode))")
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let flags = try decoder.decode(FeatureFlags.self, from: data)
                DispatchQueue.main.async {
                    self?.flags = flags
                    self?.lastUpdate = Date()
                    // Save to local cache
                    self?.saveToLocal(flags: flags)
                    print("✅ Feature Flags: Successfully loaded from GitHub!")
                    print("   - Next Door: \(flags.nextDoorEnabled ? "ENABLED" : "DISABLED")")
                    print("   - Friend Finder: \(flags.friendFinderEnabled ? "ENABLED" : "DISABLED")")
                    print("   - Map: \(flags.mapEnabled ? "ENABLED" : "DISABLED")")
                    print("   - Favorites: \(flags.favoritesEnabled ? "ENABLED" : "DISABLED")")
                }
                completion(true)
            } catch {
                print("❌ Feature Flags: Decoding error - \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("   Response data: \(jsonString.prefix(500))")
                }
                completion(false)
            }
        }
        
        task.resume()
    }
    
    private func loadFromLocal() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(localConfigFileName)
        
        if let data = try? Data(contentsOf: filePath),
           let flags = try? JSONDecoder().decode(FeatureFlags.self, from: data) {
            DispatchQueue.main.async {
                self.flags = flags
                self.lastUpdate = Date()
            }
        } else {
            // Use default flags if local file doesn't exist
            DispatchQueue.main.async {
                self.flags = .default
            }
        }
    }
    
    private func saveToLocal(flags: FeatureFlags) {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(localConfigFileName)
        
        if let data = try? JSONEncoder().encode(flags) {
            try? data.write(to: filePath)
        }
    }
    
    // Manual refresh method
    func refresh() {
        loadFlags()
    }
    
    // Test GitHub connection and print status
    func testGitHubConnection() {
        let url = remoteConfigURL
        print("🔍 Testing GitHub Feature Flags Connection...")
        print("📍 URL: \(url.isEmpty ? "Not configured" : url)")
        print("✅ Config Status: \(FeatureFlagsConfig.isConfigured ? "Configured" : "Not configured")")
        
        if !url.isEmpty, let testURL = URL(string: url) {
            let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
                if let error = error {
                    print("❌ Connection Error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        print("✅ Successfully connected to GitHub!")
                        if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                            print("📄 Response: \(jsonString.prefix(200))...")
                        }
                    } else {
                        print("❌ Failed to load. Status code: \(httpResponse.statusCode)")
                    }
                }
            }
            task.resume()
        } else {
            print("⚠️ URL not configured or invalid")
        }
    }
}

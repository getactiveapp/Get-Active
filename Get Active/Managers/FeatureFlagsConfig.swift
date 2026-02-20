import Foundation

/// Feature Flags Configuration
/// 
/// To set up your GitHub repository:
/// 1. Create a repository on GitHub (or use an existing one)
/// 2. Add a file named `feature-flags.json` in the root or a folder
/// 3. Update the values below with your GitHub details
/// 4. The app will automatically load flags from your GitHub repository
struct FeatureFlagsConfig {
    // MARK: - GitHub Configuration
    
    /// Your GitHub username
    static let githubUsername = "getactiveapp"
    
    /// Your GitHub repository name
    static let githubRepo = "Get-Active"
    
    /// Branch name (usually "main" or "master")
    static let branch = "main"
    
    /// Path to the feature-flags.json file in your repository
    /// Recommended: Use "FeatureFlags/" folder for better organization
    /// Leave as empty string "" if the file is in the root directory
    /// Example: "FeatureFlags/" if file is at FeatureFlags/feature-flags.json
    static let filePath = "FeatureFlags"
    
    // MARK: - Computed URL
    
    /// Automatically generates the GitHub raw URL
    static var remoteConfigURL: String {
        let path = filePath.isEmpty ? "feature-flags.json" : "\(filePath)/feature-flags.json"
        return "https://raw.githubusercontent.com/\(githubUsername)/\(githubRepo)/\(branch)/\(path)"
    }
    
    // MARK: - Validation
    
    /// Check if the configuration is properly set up
    static var isConfigured: Bool {
        return !githubUsername.contains("YOUR_USERNAME") &&
               !githubRepo.contains("YOUR_REPO") &&
               !githubUsername.isEmpty &&
               !githubRepo.isEmpty
    }
}





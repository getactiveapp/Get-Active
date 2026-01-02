import SwiftUI

@main
struct Get_ActiveApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var eventManager = EventManager()
    
    init() {
        // Configure email service automatically on app startup
        configureEmailService()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(eventManager)
                .preferredColorScheme(.dark)
        }
    }
    
    /// Automatically configure email service from environment variables or Keychain
    private func configureEmailService() {
        let emailService = EmailService.shared
        
        // Check if already configured (has API key)
        if emailService.isConfigured {
            return // Already configured
        }
        
        // Priority 1: Check EmailConfig file (for local development)
        if let configKey = EmailConfig.sendGridAPIKey, !configKey.isEmpty {
            emailService.configure(
                provider: .sendGrid,
                apiKey: configKey,
                fromEmail: EmailConfig.fromEmail,
                fromName: EmailConfig.fromName
            )
            print("✅ Email service configured from EmailConfig.swift")
            return
        }
        
        // Priority 2: Try to configure from environment variables
        if let sendGridKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"], !sendGridKey.isEmpty {
            let fromEmail = ProcessInfo.processInfo.environment["FROM_EMAIL"] ?? "noreply@getactive.app"
            let fromName = ProcessInfo.processInfo.environment["FROM_NAME"] ?? "Get Active"
            
            emailService.configure(
                provider: .sendGrid,
                apiKey: sendGridKey,
                fromEmail: fromEmail,
                fromName: fromName
            )
            print("✅ Email service configured from environment variables (SendGrid)")
            return
        }
        
        if let mailgunKey = ProcessInfo.processInfo.environment["MAILGUN_API_KEY"], !mailgunKey.isEmpty {
            let fromEmail = ProcessInfo.processInfo.environment["FROM_EMAIL"] ?? "noreply@getactive.app"
            let fromName = ProcessInfo.processInfo.environment["FROM_NAME"] ?? "Get Active"
            
            emailService.configure(
                provider: .mailgun,
                apiKey: mailgunKey,
                fromEmail: fromEmail,
                fromName: fromName
            )
            print("✅ Email service configured from environment variables (Mailgun)")
            return
        }
        
        // Priority 3: If no environment variables, check Keychain for saved configuration
        if let savedKey = SecureKeyManager.shared.getEmailAPIKey(), !savedKey.isEmpty {
            // Keychain has the key, but we need to determine provider
            // Default to SendGrid if key starts with SG.
            let provider: EmailService.Provider = savedKey.hasPrefix("SG.") ? .sendGrid : .sendGrid
            let fromEmail = ProcessInfo.processInfo.environment["FROM_EMAIL"] ?? "noreply@getactive.app"
            let fromName = ProcessInfo.processInfo.environment["FROM_NAME"] ?? "Get Active"
            
            emailService.configure(
                provider: provider,
                apiKey: savedKey,
                fromEmail: fromEmail,
                fromName: fromName
            )
            print("✅ Email service configured from Keychain")
            return
        }
        
        // If still not configured, log a warning
        print("⚠️ Email service not configured. Set SENDGRID_API_KEY environment variable or configure in EmailConfig.swift")
    }
}

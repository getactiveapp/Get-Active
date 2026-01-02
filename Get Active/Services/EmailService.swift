import Foundation

/// Email service for sending 2FA codes and other notifications
class EmailService {
    static let shared = EmailService()
    
    // MARK: - Configuration
    
    /// Email service provider
    enum Provider {
        case sendGrid
        case awsSES
        case mailgun
        case custom(url: String)
    }
    
    private var provider: Provider = .sendGrid
    private var apiKey: String?
    private var fromEmail: String = "noreply@getactive.app"
    private var fromName: String = "Get Active"
    
    /// Check if email service is configured
    var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    private init() {
        // Load configuration from environment or Keychain
        loadConfiguration()
    }
    
    // MARK: - Configuration
    
    /// Configure email service
    func configure(provider: Provider, apiKey: String, fromEmail: String, fromName: String = "Get Active") {
        self.provider = provider
        self.apiKey = apiKey
        self.fromEmail = fromEmail
        self.fromName = fromName
        
        // Save API key to Keychain with separate key
        saveEmailAPIKey(apiKey)
    }
    
    /// Save email API key to Keychain
    private func saveEmailAPIKey(_ key: String) {
        SecureKeyManager.shared.saveEmailAPIKey(key)
    }
    
    /// Get email API key from Keychain
    private func getEmailAPIKey() -> String? {
        return SecureKeyManager.shared.getEmailAPIKey()
    }
    
    /// Load configuration from environment or Keychain
    private func loadConfiguration() {
        // Try to load from environment variables first
        if let apiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"], !apiKey.isEmpty {
            self.apiKey = apiKey
            self.provider = .sendGrid
            // Save to Keychain for future use
            saveEmailAPIKey(apiKey)
        } else if let apiKey = ProcessInfo.processInfo.environment["MAILGUN_API_KEY"], !apiKey.isEmpty {
            self.apiKey = apiKey
            self.provider = .mailgun
            saveEmailAPIKey(apiKey)
        } else if let apiKey = ProcessInfo.processInfo.environment["AWS_SES_ACCESS_KEY"], !apiKey.isEmpty {
            self.apiKey = apiKey
            self.provider = .awsSES
            saveEmailAPIKey(apiKey)
        } else if let apiKey = getEmailAPIKey() {
            // Load from Keychain
            self.apiKey = apiKey
            // Provider is already set to .sendGrid by default
        }
        
        // Load from email from environment
        if let email = ProcessInfo.processInfo.environment["FROM_EMAIL"], !email.isEmpty {
            self.fromEmail = email
        }
        
        // Load from name from environment
        if let name = ProcessInfo.processInfo.environment["FROM_NAME"], !name.isEmpty {
            self.fromName = name
        }
    }
    
    // MARK: - Send 2FA Code
    
    /// Send 2FA verification code via email
    func send2FACode(to email: String, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let subject = "Your Get Active Verification Code"
        let body = generate2FAEmailBody(code: code)
        
        sendEmail(to: email, subject: subject, body: body, isHTML: true, completion: completion)
    }
    
    // MARK: - Send Email
    
    /// Send email using configured provider
    private func sendEmail(to: String, subject: String, body: String, isHTML: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email service not configured. Please set API key."])))
            return
        }
        
        switch provider {
        case .sendGrid:
            sendViaSendGrid(to: to, subject: subject, body: body, isHTML: isHTML, apiKey: apiKey, completion: completion)
        case .awsSES:
            sendViaAWSSES(to: to, subject: subject, body: body, isHTML: isHTML, apiKey: apiKey, completion: completion)
        case .mailgun:
            sendViaMailgun(to: to, subject: subject, body: body, isHTML: isHTML, apiKey: apiKey, completion: completion)
        case .custom(let url):
            sendViaCustom(to: to, subject: subject, body: body, isHTML: isHTML, url: url, apiKey: apiKey, completion: completion)
        }
    }
    
    // MARK: - SendGrid Implementation
    
    private func sendViaSendGrid(to: String, subject: String, body: String, isHTML: Bool, apiKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://api.sendgrid.com/v3/mail/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emailBody: [String: Any] = [
            "personalizations": [[
                "to": [["email": to]]
            ]],
            "from": [
                "email": fromEmail,
                "name": fromName
            ],
            "subject": subject,
            "content": [[
                "type": isHTML ? "text/html" : "text/plain",
                "value": body
            ]]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "EmailService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "SendGrid API error: \(httpResponse.statusCode)"])
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            }
        }.resume()
    }
    
    // MARK: - AWS SES Implementation
    
    private func sendViaAWSSES(to: String, subject: String, body: String, isHTML: Bool, apiKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // AWS SES requires AWS SDK or custom implementation
        // This is a placeholder - you'll need to implement AWS signature v4
        completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AWS SES implementation requires AWS SDK"])))
    }
    
    // MARK: - Mailgun Implementation
    
    private func sendViaMailgun(to: String, subject: String, body: String, isHTML: Bool, apiKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get Mailgun domain from environment
        guard let domain = ProcessInfo.processInfo.environment["MAILGUN_DOMAIN"], !domain.isEmpty else {
            completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mailgun domain not configured"])))
            return
        }
        
        let url = URL(string: "https://api.mailgun.net/v3/\(domain)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Mailgun uses Basic Auth
        let credentials = "api:\(apiKey)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "from", value: "\(fromName) <\(fromEmail)>"),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: isHTML ? "html" : "text", value: body)
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "EmailService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Mailgun API error: \(httpResponse.statusCode)"])
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            }
        }.resume()
    }
    
    // MARK: - Custom Implementation
    
    private func sendViaCustom(to: String, subject: String, body: String, isHTML: Bool, url: String, apiKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let customURL = URL(string: url) else {
            completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid custom URL"])))
            return
        }
        
        var request = URLRequest(url: customURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emailBody: [String: Any] = [
            "to": to,
            "from": fromEmail,
            "subject": subject,
            "body": body,
            "isHTML": isHTML
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "EmailService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Custom API error: \(httpResponse.statusCode)"])
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "EmailService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            }
        }.resume()
    }
    
    // MARK: - Email Templates
    
    private func generate2FAEmailBody(code: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #DC143C; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
                .code { font-size: 32px; font-weight: bold; color: #DC143C; text-align: center; padding: 20px; background-color: white; border-radius: 8px; letter-spacing: 8px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Get Active</h1>
                </div>
                <div class="content">
                    <h2>Your Verification Code</h2>
                    <p>Use the code below to complete your login:</p>
                    <div class="code">\(code)</div>
                    <p>This code will expire in 10 minutes.</p>
                    <p>If you didn't request this code, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>© 2024 Get Active. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
}

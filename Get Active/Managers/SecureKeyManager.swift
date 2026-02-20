import Foundation
import Security
import CommonCrypto

/// Secure storage manager using iOS Keychain for sensitive data
class SecureKeyManager {
    static let shared = SecureKeyManager()
    
    private let service = "com.getactive.app"
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    /// Save a value to Keychain
    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete existing item if it exists
        delete(key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a value from Keychain
    private func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete a value from Keychain
    private func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - API Keys
    
    /// Save OpenAI API key securely
    func saveOpenAIAPIKey(_ key: String) -> Bool {
        return save(key, forKey: "openai_api_key")
    }
    
    /// Get OpenAI API key
    func getOpenAIAPIKey() -> String? {
        return get("openai_api_key")
    }
    
    /// Delete OpenAI API key
    func deleteOpenAIAPIKey() {
        delete("openai_api_key")
    }
    
    /// Save Email API key securely
    func saveEmailAPIKey(_ key: String) -> Bool {
        return save(key, forKey: "email_api_key")
    }
    
    /// Get Email API key
    func getEmailAPIKey() -> String? {
        return get("email_api_key")
    }
    
    /// Delete Email API key
    func deleteEmailAPIKey() {
        delete("email_api_key")
    }
    
    // MARK: - Authentication Tokens
    
    /// Save authentication token (JWT)
    func saveAuthToken(_ token: String) -> Bool {
        return save(token, forKey: "auth_token")
    }
    
    /// Get authentication token
    func getAuthToken() -> String? {
        return get("auth_token")
    }
    
    /// Delete authentication token
    func deleteAuthToken() {
        delete("auth_token")
    }
    
    /// Save refresh token
    func saveRefreshToken(_ token: String) -> Bool {
        return save(token, forKey: "refresh_token")
    }
    
    /// Get refresh token
    func getRefreshToken() -> String? {
        return get("refresh_token")
    }
    
    /// Delete refresh token
    func deleteRefreshToken() {
        delete("refresh_token")
    }
    
    // MARK: - 2FA Codes
    
    /// Save 2FA verification code temporarily (with expiration)
    func save2FACode(_ code: String, expiresIn seconds: Int = 600) -> Bool {
        let expirationDate = Date().addingTimeInterval(TimeInterval(seconds))
        let codeData = "\(code)|\(expirationDate.timeIntervalSince1970)"
        return save(codeData, forKey: "2fa_code")
    }
    
    /// Get and validate 2FA code
    func get2FACode() -> String? {
        guard let codeData = get("2fa_code") else { return nil }
        
        let components = codeData.split(separator: "|")
        guard components.count == 2,
              let expirationTimestamp = Double(components[1]) else {
            delete("2fa_code")
            return nil
        }
        
        let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
        if expirationDate < Date() {
            delete("2fa_code")
            return nil
        }
        
        return String(components[0])
    }
    
    /// Delete 2FA code
    func delete2FACode() {
        delete("2fa_code")
    }
    
    // MARK: - Promo Codes
    
    /// Get the valid promo code hash for verification
    /// This uses a hash comparison so the actual code isn't stored in plain text
    private func getPromoCodeHash() -> String {
        // Store hash of the promo code (not the actual code)
        // This is a SHA256 hash of the promo code
        return "d2a5ac3c0df833ac238a16cf821471ef31015d1dd3159aa6ea38cde3e5e5c519"
    }
    
    /// Verify if a promo code is valid
    func verifyPromoCode(_ code: String) -> Bool {
        // Compare hash of input with stored hash
        let inputHash = code.sha256()
        return inputHash == getPromoCodeHash()
    }
    
    // MARK: - Clear All
    
    /// Clear all stored keys (for logout)
    func clearAll() {
        deleteOpenAIAPIKey()
        deleteEmailAPIKey()
        deleteAuthToken()
        deleteRefreshToken()
        delete2FACode()
    }
}

// Extension to compute SHA256 hash
extension String {
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}




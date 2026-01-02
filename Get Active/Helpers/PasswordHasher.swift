import Foundation
import CryptoKit

/// Utility for hashing passwords securely
class PasswordHasher {
    static let shared = PasswordHasher()
    
    private init() {}
    
    /// Hash a password using SHA-256 with salt
    /// Note: For production, use bcrypt or Argon2 on the server
    /// This is a temporary local solution
    func hash(_ password: String, salt: String? = nil) -> String {
        let saltToUse = salt ?? generateSalt()
        let saltedPassword = password + saltToUse
        let data = Data(saltedPassword.utf8)
        let hash = SHA256.hash(data: data)
        return saltToUse + ":" + hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify a password against a hash
    func verify(_ password: String, against hash: String) -> Bool {
        let components = hash.split(separator: ":")
        guard components.count == 2 else { return false }
        
        let salt = String(components[0])
        let expectedHash = String(components[1])
        
        let saltedPassword = password + salt
        let data = Data(saltedPassword.utf8)
        let computedHash = SHA256.hash(data: data)
        let computedHashString = computedHash.compactMap { String(format: "%02x", $0) }.joined()
        
        return computedHashString == expectedHash
    }
    
    /// Generate a random salt
    private func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
    
    /// Extract salt from hash
    func extractSalt(from hash: String) -> String? {
        let components = hash.split(separator: ":")
        return components.count == 2 ? String(components[0]) : nil
    }
}

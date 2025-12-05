import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Help & Support")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            HelpRow(icon: "questionmark.circle.fill", title: "FAQs", description: "Frequently asked questions") {
                                // Show FAQs
                            }
                            
                            HelpRow(icon: "envelope.fill", title: "Contact Support", description: "Get help from our team") {
                                if let url = URL(string: "mailto:support@getactive.app") {
                                    openURL(url)
                                }
                            }
                            
                            HelpRow(icon: "book.fill", title: "User Guide", description: "Learn how to use Get Active") {
                                // Show user guide
                            }
                            
                            HelpRow(icon: "exclamationmark.triangle.fill", title: "Report Issue", description: "Report a bug or problem") {
                                if let url = URL(string: "mailto:report@getactive.app") {
                                    openURL(url)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.getActiveRed)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}


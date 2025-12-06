import SwiftUI

struct EventIndexCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event Title
            Text(event.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Date and Time
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(formatDate(event.date))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text(event.startTime)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // Location
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(event.location)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            // Category Badge
            HStack {
                Image(systemName: iconForCategory(event.category))
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
                Text(event.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForCategory(event.category))
            .cornerRadius(6)
        }
        .padding(12)
        .frame(width: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func colorForCategory(_ category: EventCategory) -> Color {
        switch category {
        case .academic: return .purple
        case .technology: return .blue
        case .party: return .pink
        case .mentalHealth: return .green
        case .vendor: return .brown
        case .club: return .teal
        case .career: return .orange
        case .prayer: return .indigo
        case .other: return .getActiveRed
        }
    }
    
    private func iconForCategory(_ category: EventCategory) -> String {
        switch category {
        case .academic: return "book.fill"
        case .technology: return "laptopcomputer"
        case .party: return "music.note"
        case .mentalHealth: return "heart.fill"
        case .vendor: return "cart.fill"
        case .club: return "person.3.fill"
        case .career: return "briefcase.fill"
        case .prayer: return "hands.sparkles.fill"
        case .other: return "calendar"
        }
    }
}


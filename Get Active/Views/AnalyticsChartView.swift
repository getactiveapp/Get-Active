import SwiftUI

struct AnalyticsChartView: View {
    let title: String
    let chartType: ChartType
    let data: ChartData
    @Environment(\.dismiss) var dismiss
    
    enum ChartType {
        case views
        case likes
        case attendees
        case ratings
        case events
        case shares
    }
    
    struct ChartData {
        let values: [(String, Int)]
        let currentTotal: Int
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 25) {
                totalValueCard
                chartSection
                breakdownSection
                Spacer(minLength: 30)
            }
        }
    }
    
    private var totalValueCard: some View {
        VStack(spacing: 12) {
            Text("Total \(title)")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Text("\(data.currentTotal)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    @State private var chartDisplayMode: ChartMode = .bar
    
    enum ChartMode {
        case bar
        case pie
    }
    
    private var chartSection: some View {
        VStack(spacing: 15) {
            // Chart Mode Toggle
            HStack {
                Button(action: {
                    withAnimation {
                        chartDisplayMode = .bar
                    }
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Bar")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(chartDisplayMode == .bar ? .white : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(chartDisplayMode == .bar ? Color.getActiveRed : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    withAnimation {
                        chartDisplayMode = .pie
                    }
                }) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                        Text("Pie")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(chartDisplayMode == .pie ? .white : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(chartDisplayMode == .pie ? Color.getActiveRed : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Chart Display
            if chartDisplayMode == .bar {
                chartView
            } else {
                pieChartView
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ForEach(Array(data.values.enumerated()), id: \.offset) { index, value in
                breakdownRow(for: value)
            }
        }
        .padding(.top, 10)
    }
    
    private func breakdownRow(for value: (String, Int)) -> some View {
        HStack {
            Text(value.0)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(value.1)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.getActiveRed)
            
            if data.currentTotal > 0 {
                let percentage = Int(Double(value.1) / Double(data.currentTotal) * 100)
                Text("(\(percentage)%)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }
    
    private var maxValue: Int {
        data.values.map { $0.1 }.max() ?? 1
    }
    
    private var chartView: some View {
        VStack(spacing: 15) {
            ForEach(Array(data.values.enumerated()), id: \.offset) { index, value in
                chartRow(for: value)
            }
        }
    }
    
    private func chartRow(for value: (String, Int)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            chartRowHeader(for: value)
            chartBar(for: value)
        }
    }
    
    private func chartRowHeader(for value: (String, Int)) -> some View {
        HStack {
            Text(value.0)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text("\(value.1)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func chartBar(for value: (String, Int)) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 30)
                
                let barWidth = calculateBarWidth(value: value.1, totalWidth: geometry.size.width)
                Rectangle()
                    .fill(Color.getActiveRed)
                    .frame(width: barWidth, height: 30)
            }
        }
        .frame(height: 30)
    }
    
    private func calculateBarWidth(value: Int, totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return totalWidth * CGFloat(value) / CGFloat(maxValue)
    }
    
    private var pieChartView: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                    .frame(width: radius * 2, height: radius * 2)
                
                pieSlices(radius: radius, size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 300)
    }
    
    private func pieSlices(radius: CGFloat, size: CGSize) -> some View {
        let colors: [Color] = [.getActiveRed, .blue, .green, .orange, .purple, .pink, .teal, .yellow]
        let slices = calculatePieSlices()
        
        return ZStack {
            ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                PieSlice(startAngle: slice.start, endAngle: slice.end, radius: radius)
                    .fill(colors[index % colors.count])
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .position(x: size.width / 2, y: size.height / 2)
    }
    
    private struct PieSliceData {
        let start: Double
        let end: Double
    }
    
    private func calculatePieSlices() -> [PieSliceData] {
        var slices: [PieSliceData] = []
        var currentAngle: Double = -90 // Start from top
        
        for value in data.values {
            let percentage = data.currentTotal > 0 ? Double(value.1) / Double(data.currentTotal) : 0
            let angle = percentage * 360
            
            if angle > 0 {
                let start = currentAngle
                let end = currentAngle + angle
                slices.append(PieSliceData(start: start, end: end))
                currentAngle += angle
            }
        }
        
        return slices
    }
}

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}


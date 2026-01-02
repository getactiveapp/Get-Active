import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Central State University coordinates
    private let csuCenter = CLLocationCoordinate2D(latitude: 39.7167, longitude: -83.8833)
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.7167, longitude: -83.8833), // Central State University
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // Wider view to show campus area
    )
    
    @State private var filterMode: MapFilterMode = .csu
    
    enum MapFilterMode {
        case csu
        case allEvents
    }
    
    // Filter events based on selected mode
    private var displayedEvents: [Event] {
        switch filterMode {
        case .csu:
            return eventManager.events.filter { event in
                isCampusLocation(event.location)
            }
        case .allEvents:
            return eventManager.events
        }
    }
    
    @State private var selectedEvent: Event?
    @State private var showingEventIndex = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Map with standard Apple Maps appearance using UIViewRepresentable
            ZStack {
                StandardMapView(
                    region: $region,
                    events: displayedEvents,
                    eventManager: eventManager,
                    authManager: authManager,
                    selectedEvent: $selectedEvent
                )
                .ignoresSafeArea()
                
                // Filter Buttons at Top
                VStack {
                    HStack(spacing: 12) {
                        // CSU Filter Button
                        Button(action: {
                            withAnimation {
                                filterMode = .csu
                                region = MKCoordinateRegion(
                                    center: csuCenter,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: DeviceSize.isPad ? 18 : 16))
                                Text("CSU")
                                    .font(.system(size: DeviceSize.isPad ? 18 : 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DeviceSize.isPad ? 24 : 20)
                            .padding(.vertical, DeviceSize.isPad ? 14 : 12)
                            .background(filterMode == .csu ? Color.getActiveRed : Color.getActiveBlack.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        // All Events Filter Button
                        Button(action: {
                            withAnimation {
                                filterMode = .allEvents
                                // Zoom out to show all events
                                region = MKCoordinateRegion(
                                    center: csuCenter,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: DeviceSize.isPad ? 18 : 16))
                                Text("All Events")
                                    .font(.system(size: DeviceSize.isPad ? 18 : 16, weight: .semibold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: DeviceSize.isPad ? 14 : 12))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DeviceSize.isPad ? 24 : 20)
                            .padding(.vertical, DeviceSize.isPad ? 14 : 12)
                            .background(filterMode == .allEvents ? Color.getActiveRed : Color.getActiveBlack.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 20 : 10)
                    
                    Spacer()
                }
            }
            
            // Event Index Section
            if showingEventIndex && !displayedEvents.isEmpty {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Events (\(displayedEvents.count))")
                            .font(.system(size: DeviceSize.isPad ? 22 : 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showingEventIndex.toggle()
                            }
                        }) {
                            Image(systemName: showingEventIndex ? "chevron.down" : "chevron.up")
                                .foregroundColor(.getActiveRed)
                                .font(.system(size: DeviceSize.isPad ? 20 : 16))
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                    .background(Color.getActiveBlack)
                    
                    // Event List
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DeviceSize.isPad ? 16 : 12) {
                            ForEach(displayedEvents) { event in
                                EventIndexCard(event: event)
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                    }
                    .background(Color.getActiveBlack)
                }
                .frame(height: DeviceSize.isPad ? 220 : 180)
            } else if !showingEventIndex {
                // Collapsed header
                HStack {
                    Text("Events (\(displayedEvents.count))")
                        .font(.system(size: DeviceSize.isPad ? 20 : 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingEventIndex.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.getActiveRed)
                            .font(.system(size: DeviceSize.isPad ? 20 : 16))
                    }
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.vertical, DeviceSize.isPad ? 14 : 10)
                .background(Color.getActiveBlack)
            }
        }
        .onAppear {
            // Ensure map centers on CSU when view appears
            withAnimation {
                region = MKCoordinateRegion(
                    center: csuCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, eventManager: eventManager)
                .environmentObject(authManager)
        }
    }
    
    // Check if location is on Central State University campus
    private func isCampusLocation(_ location: String) -> Bool {
        let locationLower = location.lowercased()
        // Check for common campus location keywords
        return locationLower.contains("csu") ||
               locationLower.contains("central state") ||
               locationLower.contains("campus") ||
               locationLower.contains("student center") ||
               locationLower.contains("recreation center") ||
               locationLower.contains("campus yard") ||
               locationLower.contains("library") ||
               locationLower.contains("auditorium") ||
               locationLower.contains("gymnasium") ||
               locationLower.contains("dorm") ||
               locationLower.contains("residence") ||
               locationLower.contains("hall") ||
               locationLower.contains("building") ||
               locationLower.contains("field") ||
               locationLower.contains("stadium") ||
               locationLower.contains("quad") ||
               locationLower.contains("plaza")
    }
    
    private func getCoordinateForLocation(_ location: String) -> CLLocationCoordinate2D {
        // Central State University base coordinates
        let baseLat = 39.7167
        let baseLon = -83.8833
        
        // Map common campus locations to specific coordinates
        let locationLower = location.lowercased()
        
        // Specific campus building coordinates (relative to CSU center)
        if locationLower.contains("student center") || locationLower.contains("student union") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.001, longitude: baseLon + 0.0005)
        } else if locationLower.contains("recreation center") || locationLower.contains("rec center") || locationLower.contains("gym") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.001, longitude: baseLon + 0.001)
        } else if locationLower.contains("library") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.0005, longitude: baseLon - 0.0005)
        } else if locationLower.contains("campus yard") || locationLower.contains("quad") || locationLower.contains("plaza") {
            return CLLocationCoordinate2D(latitude: baseLat, longitude: baseLon)
        } else if locationLower.contains("stadium") || locationLower.contains("field") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.002, longitude: baseLon - 0.001)
        } else if locationLower.contains("auditorium") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.0015, longitude: baseLon + 0.001)
        } else if locationLower.contains("dorm") || locationLower.contains("residence") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.0015, longitude: baseLon - 0.0005)
        } else {
            // For other campus locations, use hash-based variation within campus bounds
            let hash = location.hash
            let latOffset = Double(hash % 200 - 100) / 10000.0 // ±0.01 degree variation
            let lonOffset = Double((hash / 200) % 200 - 100) / 10000.0
            
            return CLLocationCoordinate2D(
                latitude: baseLat + latOffset,
                longitude: baseLon + lonOffset
            )
        }
    }
}

// Event Pin View with colored pins and icons
struct EventPinView: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @State private var selectedEvent: Event?
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Button(action: {
            selectedEvent = event
        }) {
            VStack(spacing: 4) {
                // Colored pin with icon
                ZStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(pinColorForEvent(event))
                    
                    // Icon overlay
                    Image(systemName: iconForEvent(event))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: -2)
                }
                
                // Event label
                Text(event.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.getActiveBlack.opacity(0.9))
                    .cornerRadius(6)
                    .shadow(radius: 2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 140)
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, eventManager: eventManager)
                .environmentObject(authManager)
        }
    }
    
    private func pinColorForEvent(_ event: Event) -> Color {
        switch event.category {
        case .academic:
            return Color.purple
        case .technology:
            return Color.blue
        case .party:
            return Color.pink
        case .mentalHealth:
            return Color.green
        case .vendor:
            return Color.brown
        case .club:
            return Color.teal
        case .career:
            return Color.orange
        case .prayer:
            return Color.indigo
        case .other:
            return Color.getActiveRed
        }
    }
    
    private func iconForEvent(_ event: Event) -> String {
        if let iconName = event.iconName {
            return iconName
        }
        
        // Default icons based on category
        switch event.category {
        case .academic:
            return "book.fill"
        case .technology:
            return "laptopcomputer"
        case .party:
            return "music.note"
        case .mentalHealth:
            return "heart.fill"
        case .vendor:
            return "cart.fill"
        case .club:
            return "person.3.fill"
        case .career:
            return "briefcase.fill"
        case .prayer:
            return "hands.sparkles.fill"
        case .other:
            return "calendar"
        }
    }
}

// UIViewRepresentable wrapper for MKMapView with standard map type
struct StandardMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let events: [Event]
    @ObservedObject var eventManager: EventManager
    @ObservedObject var authManager: AuthenticationManager
    @Binding var selectedEvent: Event?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .standard // Explicitly set to standard map type (not red)
        mapView.region = region
        mapView.delegate = context.coordinator
        
        // Add annotations for events
        updateAnnotations(mapView: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
        mapView.mapType = .standard // Ensure standard map type (not red)
        updateAnnotations(mapView: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func getCoordinateForLocation(_ location: String) -> CLLocationCoordinate2D {
        // Central State University base coordinates
        let baseLat = 39.7167
        let baseLon = -83.8833
        
        // Map common campus locations to specific coordinates
        let locationLower = location.lowercased()
        
        // Specific campus building coordinates (relative to CSU center)
        if locationLower.contains("student center") || locationLower.contains("student union") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.001, longitude: baseLon + 0.0005)
        } else if locationLower.contains("recreation center") || locationLower.contains("rec center") || locationLower.contains("gym") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.001, longitude: baseLon + 0.001)
        } else if locationLower.contains("library") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.0005, longitude: baseLon - 0.0005)
        } else if locationLower.contains("campus yard") || locationLower.contains("quad") || locationLower.contains("plaza") {
            return CLLocationCoordinate2D(latitude: baseLat, longitude: baseLon)
        } else if locationLower.contains("stadium") || locationLower.contains("field") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.002, longitude: baseLon - 0.001)
        } else if locationLower.contains("auditorium") {
            return CLLocationCoordinate2D(latitude: baseLat + 0.0015, longitude: baseLon + 0.001)
        } else if locationLower.contains("dorm") || locationLower.contains("residence") {
            return CLLocationCoordinate2D(latitude: baseLat - 0.0015, longitude: baseLon - 0.0005)
        } else {
            // For other campus locations, use hash-based variation within campus bounds
            let hash = location.hash
            let latOffset = Double(hash % 200 - 100) / 10000.0 // ±0.01 degree variation
            let lonOffset = Double((hash / 200) % 200 - 100) / 10000.0
            
            return CLLocationCoordinate2D(
                latitude: baseLat + latOffset,
                longitude: baseLon + lonOffset
            )
        }
    }
    
    private func updateAnnotations(mapView: MKMapView) {
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add new annotations
        for event in events {
            let annotation = EventAnnotation(event: event, coordinate: getCoordinateForLocation(event.location))
            mapView.addAnnotation(annotation)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: StandardMapView
        var onEventSelected: ((Event) -> Void)?
        
        init(_ parent: StandardMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let eventAnnotation = annotation as? EventAnnotation else {
                return nil
            }
            
            let identifier = "EventPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom pin view using SwiftUI
            let event = eventAnnotation.event
            let pinColor = pinColorForEvent(event)
            let iconName = iconForEvent(event)
            
            // Use a simple approach with system images
            let pinImage = UIImage(systemName: "mappin.circle.fill")
            let pinImageView = UIImageView(image: pinImage)
            pinImageView.tintColor = pinColor // pinColor is already UIColor
            pinImageView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            
            let iconImage = UIImage(systemName: iconName)
            let iconImageView = UIImageView(image: iconImage)
            iconImageView.tintColor = .white
            iconImageView.frame = CGRect(x: 8, y: 4, width: 16, height: 16)
            iconImageView.contentMode = .scaleAspectFit
            
            // Create container view
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
            containerView.addSubview(pinImageView)
            containerView.addSubview(iconImageView)
            
            annotationView?.image = containerView.asImage()
            annotationView?.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            
            // Make annotation view tappable
            annotationView?.isEnabled = true
            annotationView?.canShowCallout = false
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let eventAnnotation = view.annotation as? EventAnnotation else {
                return
            }
            
            // Handle tap - pass event back to SwiftUI
            DispatchQueue.main.async {
                self.parent.selectedEvent = eventAnnotation.event
            }
            
            // Deselect to allow re-selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        }
        
        private func pinColorForEvent(_ event: Event) -> UIColor {
            switch event.category {
            case .academic:
                return .systemPurple
            case .technology:
                return .systemBlue
            case .party:
                return .systemPink
            case .mentalHealth:
                return .systemGreen
            case .vendor:
                return .brown
            case .club:
                return .systemTeal
            case .career:
                return .systemOrange
            case .prayer:
                return .systemIndigo
            case .other:
                return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // Red but not the map background
            }
        }
        
        private func iconForEvent(_ event: Event) -> String {
            if let iconName = event.iconName {
                return iconName
            }
            
            // Default icons based on category
            switch event.category {
            case .academic:
                return "book.fill"
            case .technology:
                return "laptopcomputer"
            case .party:
                return "music.note"
            case .mentalHealth:
                return "heart.fill"
            case .vendor:
                return "cart.fill"
            case .club:
                return "person.3.fill"
            case .career:
                return "briefcase.fill"
            case .prayer:
                return "hands.sparkles.fill"
            case .other:
                return "calendar"
            }
        }
    }
}

// Extension to convert UIView to UIImage
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// Custom annotation class for events
class EventAnnotation: NSObject, MKAnnotation {
    let event: Event
    let coordinate: CLLocationCoordinate2D
    
    init(event: Event, coordinate: CLLocationCoordinate2D) {
        self.event = event
        self.coordinate = coordinate
        super.init()
    }
}

#Preview {
    MapView()
}


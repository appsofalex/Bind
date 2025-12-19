import SwiftUI

// MARK: - NEW: BOARDING PASS LOGIC

// Helper shape for the runway line
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// The detailed, expanded view for the Boarding Pass
struct BoardingPassDetailView: View {
    let document: TravelDocument
    let animate: Bool // Triggers the plane flight
    
    // Formatter for Date: "14 OCT"
    var flightDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f
    }
    
    // Formatter for Time: "10:20"
    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
    
    private func parseAirportInfo(from string: String?) -> (code: String, city: String) {
        guard let string = string, !string.isEmpty else {
            return ("TBD", "UNKNOWN")
        }
        
        // Find the last occurrence of " (" to get the code part
        if let range = string.range(of: " (", options: .backwards) {
            let city = String(string[..<range.lowerBound])
            
            // Extract the code between "(" and ")"
            let start = string.index(range.lowerBound, offsetBy: 2)
            if let endRange = string.range(of: ")", options: .backwards, range: start..<string.endIndex) {
                let code = String(string[start..<endRange.lowerBound])
                return (code, city.uppercased())
            }
        }
        
        // Fallback if the format is not "City (CODE)"
        // Assume the whole string is the code.
        return (string.uppercased(), "")
    }
    
    var body: some View {
        
        let brandColor = getAirlineColor(name: document.airline)
        let originInfo = parseAirportInfo(from: document.origin)
        let destinationInfo = parseAirportInfo(from: document.title)
        
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99) // Off-white paper texture
            
            VStack(spacing: 0) {
                // 1. Airline Header
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.white)
                    // Use dynamic airline name or default
                    Text(document.airline.isEmpty ? "AIRLINE" : document.airline.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                // Use brand color for header
                .background(brandColor)
                
                // 2. Flight Path Animation Area
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(originInfo.code)
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.black)
                            if !originInfo.city.isEmpty {
                                Text(originInfo.city)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(destinationInfo.code)
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.black)
                            if !destinationInfo.city.isEmpty {
                                Text(destinationInfo.city)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 25)
                    
                    // Animated Runway
                    ZStack {
                        // Dashed Line
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.4))
                        
                        // The Plane
                        GeometryReader { geo in
                            Image(systemName: "airplane.departure") // CHANGED: explicitly using departure icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24)
                                // Use requisite brand color for the plane icon
                                .foregroundColor(brandColor)
                                .rotationEffect(.degrees(0))
                                .offset(x: animate ? geo.size.width - 24 : 0)
                        }
                        .frame(height: 24)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // 3. Flight Info Grid
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        FieldView(label: "FLIGHT NO.", value: document.detailValue)
                        FieldView(label: "DATE", value: document.flightDate.map { flightDateFormatter.string(from: $0).uppercased() } ?? "TBD")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FieldView(label: "TIME", value: document.boardingTime.map { timeFormatter.string(from: $0) } ?? "TBD")
                        FieldView(label: "GATE", value: document.gate.flatMap { $0.isEmpty ? nil : $0 } ?? "TBD")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FieldView(label: "SEAT", value: document.seat ?? "ANY")
                        FieldView(label: "CLASS", value: document.flightClass?.uppercased() ?? "ECONOMY")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(25)
                
                Spacer()
                
                // 4. Tear-off Stub / Footer
                VStack {
                    HStack {
                        Image(systemName: "qrcode")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.black.opacity(0.8))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ELECTRONIC TICKET")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            Text("ETKT 123 999 000 22")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(20)
                .background(Color.gray.opacity(0.08))
                .overlay(
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5)),
                    alignment: .top
                )
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // --- AIRLINE COLOR LOGIC ---
    func getAirlineColor(name: String) -> Color {
        let n = name.lowercased()
        
        // Existing
        if n.contains("british") { return Color(red: 0.0, green: 0.13, blue: 0.4) }
        if n.contains("american") { return Color(red: 0.1, green: 0.3, blue: 0.6) }
        if n.contains("delta") { return Color(red: 0.0, green: 0.2, blue: 0.4) }
        if n.contains("united") { return Color(red: 0.0, green: 0.35, blue: 0.7) }
        if n.contains("emirates") { return Color(red: 0.8, green: 0.0, blue: 0.0) }
        if n.contains("qatar") { return Color(red: 0.4, green: 0.0, blue: 0.2) }
        if n.contains("ryanair") { return Color(red: 0.05, green: 0.2, blue: 0.6) }
        
        // NEW ADDITIONS
        if n.contains("air canada") { return Color(red: 0.9, green: 0.0, blue: 0.0) } // Red
        if n.contains("japan") { return Color(red: 0.8, green: 0.0, blue: 0.0) } // Red Crane
        if n.contains("china") { return Color(red: 0.8, green: 0.0, blue: 0.0) } // Red Phoenix
        if n.contains("lufthansa") { return Color(red: 0.02, green: 0.1, blue: 0.3) } // Deep Blue
        if n.contains("qantas") { return Color(red: 0.8, green: 0.0, blue: 0.0) } // Red Roo
        if n.contains("easyjet") { return Color(red: 1.0, green: 0.4, blue: 0.0) } // Orange
        if n.contains("singapore") { return Color(red: 0.1, green: 0.1, blue: 0.4) } // Navy/Gold pattern usually, but Navy is safe
        // Others
        if n.contains("virgin") { return Color(red: 0.8, green: 0.05, blue: 0.15) }
        if n.contains("jet2") { return Color(red: 0.85, green: 0.1, blue: 0.1) }
        if n.contains("france") { return Color(red: 0.0, green: 0.15, blue: 0.4) }
        
        // Default Fallback
        return document.primaryColor
    }
}
// The Animation Wrapper for Boarding Pass
struct BoardingPassAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    // Animation States
    @State private var showDetail = false
    @State private var planeMoved = false
    
    var body: some View {
        ZStack {
            if showDetail {
                BoardingPassDetailView(document: document, animate: planeMoved)
                    .transition(.identity) // Simple swap
            } else {
                DocumentCardView(document: document)
                    .transition(.identity)
            }
        }
        .frame(height: isSelected ? 440 : 240) // Expand vertically
        .mask(RoundedRectangle(cornerRadius: 20))
        
        // --- TAKE OFF TILT EFFECT ---
        // When selected, tilt X up slightly to look like it's lifting off the runway
        .rotation3DEffect(
            .degrees(isSelected ? -5 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        // Add dynamic shadow
        // REMOVE HUE: No shadow color when selected
        .shadow(
            color: isSelected ? Color.clear : Color.black.opacity(0.3),
            radius: isSelected ? 0 : 15,
            x: 0,
            y: isSelected ? 0 : 10
        )
        .onTapGesture {
            onTap()
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                // EXPAND
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showDetail = true
                }
                // TRIGGER PLANE AFTER EXPANSION STARTS
                // Faster flight (1.5s instead of 2.5s)
                withAnimation(.easeInOut(duration: 1.5).delay(0.2)) {
                    planeMoved = true
                }
            } else {
                // COLLAPSE
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showDetail = false
                    planeMoved = false
                }
            }
        }
    }
}

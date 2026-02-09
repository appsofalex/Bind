import SwiftUI

// MARK: - EVENT VIEWS

struct EventDetailView: View {
    let document: TravelDocument
    
    // Animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    var eventDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }
    
    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99)
            
            VStack(spacing: 0) {
                // 1. Header with Event Type
                HStack {
                    Image(systemName: getEventTypeIcon(document.eventType ?? "Other"))
                        .foregroundColor(.white)
                    Text(document.eventType?.capitalized ?? "Event")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text("ADMIT ONE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(document.primaryColor)
                
                VStack(alignment: .leading, spacing: 20) {
                    // 2. Event Name & Venue
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.title.uppercased())
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(document.primaryColor)
                            Text(document.venueName ?? "VENUE TBD")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        if let location = document.venueLocation, !location.isEmpty {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 10)
                    
                    Divider()
                    
                    // 3. Date & Time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DATE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Text(document.eventDate.map { eventDateFormatter.string(from: $0) } ?? "TBD")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TICKET TYPE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Text(document.ticketType?.capitalized ?? "Standard")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(document.primaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(document.primaryColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TIME")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Text(document.eventDate.map { timeFormatter.string(from: $0) } ?? "TBD")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 4. Seating Info
                    HStack(spacing: 0) {
                        SeatField(label: "SECTION", value: document.section ?? "ANY")
                        SeatField(label: "ROW", value: document.row ?? "ANY")
                        SeatField(label: "SEAT", value: document.seat ?? "ANY")
                    }
                }
                .padding(25)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                
                Spacer()
                
                // 5. Barcode Area
                VStack(spacing: 12) {
                    HStack {
                        // Using a simple barcode-like representation
                        HStack(spacing: 2) {
                            ForEach(0..<20) { _ in
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: CGFloat.random(in: 1...4), height: 40)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TICKET NO.")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.detailValue)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 20)
                }
                .background(Color.gray.opacity(0.05))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
    
    func getEventTypeIcon(_ type: String) -> String {
        switch type {
        case "Concert": return "music.note"
        case "Sports": return "figure.run"
        case "Theatre": return "theatermasks.fill"
        case "Cinema": return "film.fill"
        case "Conference": return "person.2.fill"
        case "Festival": return "tent.fill"
        case "Museum": return "building.columns.fill"
        default: return "ticket.fill"
        }
    }
}

struct SeatField: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            if isSelected {
                EventDetailView(document: document)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            } else {
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 500 : 240)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

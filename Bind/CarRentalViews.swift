import SwiftUI

// MARK: - CAR RENTAL ANIMATED CARD
struct CarRentalAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    @State private var carOffset: CGFloat = 100
    
    var body: some View {
        let brandColor = getCarBrandColor(for: document.title)
        
        ZStack {
            if isBackVisible {
                // BACK SIDE - Detailed View
                CarRentalBackView(document: document, brandColor: brandColor)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT SIDE - Standard Card
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 450 : 240)
        .rotation3DEffect(
            .degrees(yRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.8
        )
        .onTapGesture { onTap() }
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = false
                }
            }
        }
    }
}

// MARK: - BACK VIEW
struct CarRentalBackView: View {
    let document: TravelDocument
    let brandColor: Color
    
    var body: some View {
        ZStack {
            // Background
            brandColor
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(alignment: .leading, spacing: 15) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(document.title.uppercased())
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Text("RENTAL AGREEMENT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "car.2.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(.bottom, 10)
                
                // Car Info
                if let car = document.carModel, !car.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("VEHICLE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        Text(car)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Reservation
                VStack(alignment: .leading, spacing: 5) {
                    Text("RESERVATION NUMBER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.6))
                    Text(document.detailValue)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Divider().background(.white.opacity(0.3))
                
                // Pickup/Dropoff Grid
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("PICK-UP", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if let loc = document.pickupLocation, !loc.isEmpty {
                                Text(loc)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if let date = document.pickupDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("DROP-OFF", systemImage: "arrow.up.circle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if let loc = document.dropoffLocation, !loc.isEmpty {
                                Text(loc)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if let date = document.dropoffDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Barcode or QR
                    VStack {
                        Spacer()
                        Image(systemName: "qrcode")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Footer
                Text(document.holderName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(25)
        }
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - BRAND COLORS
func getCarBrandColor(for brand: String) -> Color {
    let name = brand.lowercased()
    
    if name.contains("hertz") { return Color(red: 1.0, green: 0.8, blue: 0.0) } // Yellow
    if name.contains("avis") { return Color(red: 0.83, green: 0.0, blue: 0.07) } // Red
    if name.contains("europcar") { return Color(red: 0.0, green: 0.5, blue: 0.18) } // Green
    if name.contains("sixt") { return Color(red: 1.0, green: 0.37, blue: 0.0) } // Orange
    if name.contains("enterprise") { return Color(red: 0.0, green: 0.39, blue: 0.25) } // Green
    if name.contains("budget") { return Color(red: 0.0, green: 0.16, blue: 0.41) } // Blue
    if name.contains("national") { return Color(red: 0.0, green: 0.42, blue: 0.3) } // Green
    if name.contains("alamo") { return Color(red: 0.0, green: 0.21, blue: 0.5) } // Blue
    if name.contains("dollar") { return Color(red: 0.0, green: 0.34, blue: 0.72) } // Blue
    if name.contains("thrifty") { return Color(red: 0.0, green: 0.18, blue: 0.45) } // Blue
    if name.contains("goldcar") { return Color(red: 0.0, green: 0.36, blue: 0.67) } // Blue
    if name.contains("centauro") { return Color(red: 0.0, green: 0.29, blue: 0.53) } // Blue
    if name.contains("virtuo") { return Color(red: 0.0, green: 0.63, blue: 0.61) } // Teal
    if name.contains("keddy") { return Color(red: 0.0, green: 0.5, blue: 0.18) } // Green
    if name.contains("record go") { return Color(red: 0.89, green: 0.02, blue: 0.07) } // Red
    if name.contains("locauto") { return Color(red: 0.0, green: 0.25, blue: 0.5) } // Blue
    
    return Color(red: 0.1, green: 0.4, blue: 0.2) // Default Green
}

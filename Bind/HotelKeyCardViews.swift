import SwiftUI

// MARK: - HOTEL KEY CARD ANIMATION WRAPPER
struct HotelKeyAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    @State private var showCheckmark = false
    @State private var keyOffset: CGFloat = 50
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK OF CARD (Details)
                HotelKeyBackView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT OF CARD
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 450 : 240) // Slightly taller for more info
        .rotation3DEffect(
            .degrees(yRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.8
        )
        .onTapGesture { onTap() }
        .onChange(of: isSelected) { newValue in
            if newValue {
                // FLIP OPEN
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                    
                    // Trigger back-side animations
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        keyOffset = 0
                        showCheckmark = true
                    }
                }
            } else {
                // FLIP CLOSE
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = false
                }
                
                // Reset animations
                keyOffset = 50
                showCheckmark = false
            }
        }
    }
}

// MARK: - BACK VIEW
struct HotelKeyBackView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 450)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
            // Background
            Color(red: 0.1, green: 0.1, blue: 0.12) // Dark elegant background
            
            // Subtle texture or pattern
            VStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [document.primaryColor.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 150)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 15) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title.uppercased())
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        Text("GUEST INFORMATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(document.primaryColor)
                            .tracking(2)
                    }
                    Spacer()
                    Image(systemName: document.iconName)
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 5)
                
                // Grid of Info
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        InfoItem(label: "GUEST", value: document.holderName)
                        Spacer()
                        InfoItem(label: "ROOM", value: document.detailValue, alignment: .trailing)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(alignment: .top) {
                        InfoItem(label: "CHECK-IN", value: document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "---")
                        Spacer()
                        InfoItem(label: "CHECK-OUT", value: document.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "---", alignment: .trailing)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(alignment: .top) {
                        InfoItem(label: "RESERVATION", value: document.reservationNumber ?? "---")
                        Spacer()
                        InfoItem(label: "ROOM TYPE", value: document.roomType ?? "---", alignment: .trailing)
                    }
                    
                    if let loyalty = document.loyaltyNumber, !loyalty.isEmpty {
                        Divider().background(Color.white.opacity(0.1))
                        InfoItem(label: "LOYALTY NUMBER", value: loyalty)
                    }
                }
                
                Spacer()
                
                // Extra details section (WiFi, Address)
                VStack(alignment: .leading, spacing: 10) {
                    if let wifi = document.wifiPassword, !wifi.isEmpty {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(document.primaryColor)
                            Text("WiFi: \(wifi)")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    if let phone = document.hotelPhoneNumber, !phone.isEmpty {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(document.primaryColor)
                            Text(phone)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    if let address = document.hotelAddress, !address.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(document.primaryColor)
                            Text(address)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.top, 5)
            }
            .padding(25)
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

fileprivate struct InfoItem: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            Text(value.isEmpty ? "---" : value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

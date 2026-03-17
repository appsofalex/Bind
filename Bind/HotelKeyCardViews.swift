import SwiftUI

// MARK: - HOTEL KEY CARD ANIMATION WRAPPER
struct HotelKeyAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    /// Whether the animated door+key lock is visible (used only during the unlock animation).
    @State private var showLockShell: Bool = false
    /// Whether the lock is in the "unlocked" pose (door open, colored lock dot, rotated key).
    @State private var showCheckmark: Bool = false
    /// Horizontal offset for the animated key as it slides into the lock.
    /// Start further to the right so the key appears to enter from the card's right edge.
    @State private var keyOffset: CGFloat = 80
    /// Rotation for the single key icon (starts flat at -90º, ends upright at 0º).
    @State private var keyRotation: Double = -90
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK OF CARD (Details)
                HotelKeyBackView(
                    document: document,
                    keyOffset: keyOffset,
                    keyRotation: keyRotation,
                    showCheckmark: showCheckmark,
                    showLockShell: showLockShell
                )
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
                    
                    // Prepare lock shell + key for animation (no animation for initial state)
                    withAnimation(.none) {
                        showLockShell = true
                        keyOffset = 80      // start off to the right edge
                        keyRotation = -90   // flat / horizontal
                        showCheckmark = false
                    }
                    
                    // Key slides into the lock, coming in flat
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.78).delay(0.18)) {
                        keyOffset = 0
                    }
                    // Door flips to open + lock glows
                    withAnimation(.easeInOut(duration: 0.35).delay(0.46)) {
                        showCheckmark = true
                    }
                    // Same key rotates up 90º into its final upright state
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.46)) {
                        keyRotation = 0
                    }
                    // Then the whole door+key shell fades away, revealing the static white key icon
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLockShell = false
                        }
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
                
                // Reset animations (no animated snap-back)
                withAnimation(.none) {
                    keyOffset = 80
                    keyRotation = -90
                    showCheckmark = false
                    showLockShell = false
                }
            }
        }
    }
}

// MARK: - BACK VIEW
struct HotelKeyBackView: View {
    let document: TravelDocument
    let keyOffset: CGFloat
    let keyRotation: Double
    let showCheckmark: Bool
    let showLockShell: Bool
    
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
                    ZStack {
                        // Single persistent key (white), used both during and after the animation.
                        Image(systemName: "key.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: keyOffset, y: 0) // keep Y fixed so it doesn't "swing" in
                            .rotationEffect(.degrees(keyRotation), anchor: .trailing)
                            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 3)
                        
                        if showLockShell {
                            // Animated lock shell (door + lock dot) that appears only during the unlock animation.
                            ZStack {
                                    // Door icon only (no border frame, no lock dot)
                                    Image(systemName: showCheckmark ? "door.left.hand.open" : "door.left.hand.closed")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                            }
                            .transition(.opacity)
                        }
                    }
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

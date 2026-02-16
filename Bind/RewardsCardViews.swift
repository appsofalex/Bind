import SwiftUI

// MARK: - REWARDS CARD ANIMATION WRAPPER
struct RewardsAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    // Determine the subtype based on subtitle/title (matching Form logic)
    private var rewardType: String {
        let sub = document.subtitle.uppercased()
        if sub.contains("COFFEE") { return "Coffee" }
        if sub.contains("FREQUENT FLYER") || sub.contains("AIRLINE") { return "Airline" }
        if sub.contains("SUPERMARKET") || sub.contains("GROCERY") { return "Supermarket" }
        return "Generic"
    }
    
    var body: some View {
        let brandColor = getBrandColor(for: document)
        
        Group {
            switch rewardType {
            case "Coffee":
                CoffeeRewardsView(document: document, brandColor: brandColor, isSelected: isSelected, onTap: onTap)
            case "Airline":
                AirlineRewardsView(document: document, brandColor: brandColor, isSelected: isSelected, onTap: onTap)
            case "Supermarket":
                SupermarketRewardsView(document: document, brandColor: brandColor, isSelected: isSelected, onTap: onTap)
            default:
                // Fallback to standard flip for generic rewards
                IDFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            }
        }
    }
    
    // MARK: - BRAND COLOR LOGIC
    func getBrandColor(for doc: TravelDocument) -> Color {
        let name = doc.title.lowercased()
        
        // COFFEE BRANDS
        if name.contains("starbucks") { return Color(red: 0.0, green: 0.44, blue: 0.29) }
        if name.contains("pret") { return Color(red: 0.6, green: 0.0, blue: 0.2) }
        if name.contains("costa") { return Color(red: 0.45, green: 0.13, blue: 0.19) }
        if name.contains("philz") { return Color(red: 0.45, green: 0.76, blue: 0.71) }
        if name.contains("nero") { return Color(red: 0.1, green: 0.2, blue: 0.45) }
        if name.contains("tim hortons") { return Color(red: 0.8, green: 0.0, blue: 0.1) }
        if name.contains("dunkin") { return Color(red: 1.0, green: 0.4, blue: 0.0) }
        if name.contains("mccafé") || name.contains("mccafe") { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        
        // SUPERMARKET BRANDS
        if name.contains("waitrose") { return Color(red: 0.36, green: 0.54, blue: 0.0) }
        if name.contains("tesco") { return Color(red: 0.0, green: 0.33, blue: 0.7) }
        if name.contains("sainsbury") { return Color(red: 1.0, green: 0.4, blue: 0.0) }
        if name.contains("m&s") || name.contains("marks") { return Color(red: 0.0, green: 0.3, blue: 0.1) }
        if name.contains("co-op") || name.contains("coop") { return Color(red: 0.0, green: 0.68, blue: 0.94) }
        if name.contains("asda") { return Color(red: 0.47, green: 0.72, blue: 0.0) }
        if name.contains("morrisons") { return Color(red: 0.0, green: 0.4, blue: 0.2) }
        if name.contains("lidl") { return Color(red: 0.0, green: 0.31, blue: 0.63) }
        if name.contains("aldi") { return Color(red: 0.0, green: 0.16, blue: 0.44) }
        
        // AIRLINE BRANDS (Matching BoardingPassViews)
        if name.contains("british") { return Color(red: 0.0, green: 0.13, blue: 0.4) }
        if name.contains("american") { return Color(red: 0.1, green: 0.3, blue: 0.6) }
        if name.contains("delta") { return Color(red: 0.0, green: 0.2, blue: 0.4) }
        if name.contains("united") { return Color(red: 0.0, green: 0.35, blue: 0.7) }
        if name.contains("emirates") { return Color(red: 0.8, green: 0.0, blue: 0.0) }
        if name.contains("qatar") { return Color(red: 0.4, green: 0.0, blue: 0.2) }
        if name.contains("ryanair") { return Color(red: 0.05, green: 0.2, blue: 0.6) }
        if name.contains("air canada") { return Color(red: 0.9, green: 0.0, blue: 0.0) }
        if name.contains("japan") { return Color(red: 0.8, green: 0.0, blue: 0.0) }
        if name.contains("china") { return Color(red: 0.8, green: 0.0, blue: 0.0) }
        if name.contains("lufthansa") { return Color(red: 0.02, green: 0.1, blue: 0.3) }
        if name.contains("qantas") { return Color(red: 0.8, green: 0.0, blue: 0.0) }
        if name.contains("easyjet") { return Color(red: 1.0, green: 0.4, blue: 0.0) }
        if name.contains("singapore") { return Color(red: 0.1, green: 0.1, blue: 0.4) }
        if name.contains("virgin") { return Color(red: 0.8, green: 0.05, blue: 0.15) }
        if name.contains("jet2") { return Color(red: 0.85, green: 0.1, blue: 0.1) }
        if name.contains("france") { return Color(red: 0.0, green: 0.15, blue: 0.4) }

        return doc.primaryColor
    }
}

// MARK: - 1. COFFEE REWARDS ANIMATION
struct CoffeeRewardsView: View {
    let document: TravelDocument
    let brandColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var fillLevel: CGFloat = 0.0
    @State private var steamOpacity: Double = 0.0
    
    // Flip State
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // DETAILED VIEW (Back)
                ZStack {
                    if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 400)
                            .clipped()
                    } else {
                    Color(red: 0.98, green: 0.96, blue: 0.93) // Cream paper
                    
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text(document.title.uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(brandColor)
                            Spacer()
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title2)
                                .foregroundColor(brandColor)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Animated Cup
                        ZStack(alignment: .bottom) {
                            // Cup Outline
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                                .foregroundColor(.gray.opacity(0.2))
                            
                            // Liquid Fill (Masked)
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                                .foregroundColor(brandColor)
                                .mask(
                                    GeometryReader { geo in
                                        VStack {
                                            Spacer()
                                            Rectangle()
                                                .frame(height: geo.size.height * fillLevel)
                                        }
                                    }
                                )
                            
                            // Steam
                            HStack(spacing: 8) {
                                ForEach(0..<3) { i in
                                    Capsule()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: 4, height: 20)
                                        .offset(y: steamOpacity > 0 ? -30 : 0)
                                        .opacity(steamOpacity)
                                        .animation(
                                            .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.2),
                                            value: steamOpacity
                                        )
                                }
                            }
                            .offset(y: -50)
                        }
                        .padding(.vertical, 30)
                        
                        // Points / Status
                        VStack(spacing: 5) {
                            Text("CURRENT BALANCE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("1,250 PTS") // Placeholder logic
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Barcode
                        Image(systemName: "barcode.viewfinder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 40)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.bottom, 20)
                    }
                    }
                }
                .cornerRadius(20)
                // Correct flip orientation for the back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // COVER (Front)
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 400 : 240)
        // MAIN FLIP ROTATION
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
                
                // Show Back Face
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                    
                    // Trigger animations AFTER view is mounted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Animate Fill using Cubic Bezier
                        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 1.2)) {
                            fillLevel = 0.8
                        }
                        // Steam starts after
                        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
                            steamOpacity = 1.0
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
                
                // Reset States
                fillLevel = 0.0
                steamOpacity = 0.0
            }
        }
    }
}

// MARK: - 2. AIRLINE REWARDS ANIMATION
struct AirlineRewardsView: View {
    let document: TravelDocument
    let brandColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var planeOffset: CGFloat = 0
    @State private var planeOpacity: Double = 0
    
    // Flip State
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK
                ZStack {
                    if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 400)
                            .clipped()
                    } else {
                    // Sky Background
                    LinearGradient(
                        colors: [Color(red: 0.8, green: 0.9, blue: 1.0), .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Cloud Decor
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .offset(x: 80, y: -100)
                        .opacity(0.8)
                    
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .offset(x: -100, y: -50)
                        .opacity(0.6)
                    
                    VStack {
                        // Header
                        HStack {
                            Text("FREQUENT FLYER")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(brandColor)
                            Spacer()
                            Image(systemName: "airplane.circle.fill")
                                .font(.title)
                                .foregroundColor(brandColor)
                        }
                        .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Text(document.title.uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(document.holderName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Membership Info
                        HStack {
                            VStack(alignment: .leading) {
                                Text("STATUS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text("GOLD")
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.0))
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("MEMBER NO.")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text(document.detailValue)
                                    .font(.subheadline)
                                    .fontWeight(.heavy)
                                    .fontDesign(.monospaced)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(20)
                        .background(brandColor.opacity(0.6))
                        .background(.ultraThickMaterial) 
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .padding()
                    }
                    
                    // Flying Plane Animation - UPDATED PATH
                    GeometryReader { geo in
                        Image(systemName: "airplane.departure") // Taking off icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40)
                            .foregroundColor(brandColor)
                            // Start bottom-left, fly to top-right
                            // To match -20 rotation (climbing), vector should vary Y by -tan(20)*X = -0.36*X
                            // But rotation -20 rotates the frame around the center.
                            // If we move along X and Y, we want the path to align.
                            // Start pos:
                            .offset(x: -50, y: 50) 
                            .rotationEffect(.degrees(-20)) 
                            // If we animate offset:
                            // We want to move from (-50, 50) to (250, -60) approx.
                            // Delta X = 300. Delta Y = -110.
                            // Slope = -110/300 = -0.366. This matches tan(20) perfectly.
                            .offset(x: planeOffset, y: planeOffset * -0.36) 
                            .opacity(planeOpacity)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    }
                }
                .cornerRadius(20)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 400 : 240)
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
                
                // Show Back Face
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                    
                    // Trigger animations AFTER view is mounted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Fly the plane
                        planeOffset = -150
                        planeOpacity = 0
                        
                        // Fade in
                        withAnimation(.easeOut(duration: 0.5)) {
                            planeOpacity = 1
                        }
                        
                        // Move across
                        withAnimation(.timingCurve(0.2, 0.0, 0.2, 1, duration: 2.5)) {
                            planeOffset = 300 // Fly off screen to right
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
                
                // Reset
                planeOffset = -150
                planeOpacity = 0
            }
        }
    }
}

// MARK: - 3. SUPERMARKET REWARDS ANIMATION
struct SupermarketRewardsView: View {
    let document: TravelDocument
    let brandColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var cardOffset: CGFloat = -200
    @State private var basketScale: CGFloat = 0.5
    
    // Flip State
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK
                ZStack {
                    if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 400)
                            .clipped()
                    } else {
                    Color.white
                    
                    // Background Pattern (subtle grid)
                    VStack(spacing: 20) {
                        ForEach(0..<10) { _ in
                            Divider().opacity(0.3)
                        }
                    }
                    .rotationEffect(.degrees(45))
                    .opacity(0.1)
                    
                    VStack {
                        // Header
                        HStack {
                            Text(document.title.uppercased())
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(brandColor)
                            Spacer()
                            Image(systemName: "basket.fill")
                                .foregroundColor(brandColor)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Basket Animation Centerpiece
                        ZStack {
                            // The "Card" dropping in (Moved behind basket)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(brandColor)
                                .frame(width: 60, height: 40)
                                .overlay(
                                    Text(document.title.prefix(1))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .rotationEffect(.degrees(15))
                                .offset(y: cardOffset)
                                // Mask allows card to be seen only above the "rim" level
                                // Hides it as it falls "into" the basket
                                .mask(
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: 200, height: 200) // Widened to prevent edge clipping
                                        .offset(y: -115) // Adjust cutoff point to match basket rim
                                )
                            
                            // Basket (Front)
                            Image(systemName: "basket.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                                .foregroundColor(brandColor.opacity(0.3))
                                .scaleEffect(basketScale)
                        }
                        .frame(height: 120)
                        
                        Spacer()
                        
                        // Barcode Section
                        VStack(spacing: 5) {
                            Text("SCAN AT CHECKOUT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            // Simulated Barcode
                            HStack(spacing: 2) {
                                ForEach(0..<30) { _ in
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: CGFloat.random(in: 1...4), height: 50)
                                }
                            }
                            
                            Text(document.detailValue)
                                .font(.system(.caption, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(brandColor)
                    }
                    .padding(.bottom, 30)
                }
                }
                }
                .cornerRadius(20)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 400 : 240)
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
                
                // Show Back Face
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                    
                    // Trigger animations AFTER view is mounted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Animate Basket Pop
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            basketScale = 1.0
                        }
                        
                        // Animate Card Drop
                        cardOffset = -100
                        withAnimation(.timingCurve(0.68, -0.55, 0.265, 1.55, duration: 0.8).delay(0.2)) {
                            cardOffset = 40 // Drop lower to fully hide
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
                
                // Reset
                basketScale = 0.5
                cardOffset = -200
            }
        }
    }
}


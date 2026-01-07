import SwiftUI

// MARK: - NEW: REALISTIC PASSPORT COVER (For "Folded" Animation)
struct PassportCoverView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            // Dark Navy Leather Texture
            document.primaryColor
            
            VStack(spacing: 30) {
                Spacer()
                
                // DYNAMIC TITLE (Split title into multiple lines if needed)
                Text(document.title.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5)) // Gold
                    .tracking(1)
                    .padding(.horizontal)
                
                Image(systemName: "crown.fill") // Simplified crest
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                
                Text("PASSPORT")
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                    .tracking(4)
                
                Spacer()
                
                Image(systemName: "rectangle.inset.filled.and.person.filled") // Biometric symbol
                    .font(.title)
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                    .padding(.bottom, 30)
            }
            .padding()
        }
        .frame(height: 240) // Match card height exactly
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}


// MARK: - NEW: PASSPORT INTERIOR VIEW (Foldable)
struct PassportInteriorView: View {
    let document: TravelDocument
    let isOpen: Bool // Controls the vertical fold
    
    // Date Formatter Helper
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }
    
    // Name Splitter Helper (Simple Logic)
    var names: (surname: String, given: String) {
        let components = document.holderName.components(separatedBy: " ")
        if let last = components.last {
            let given = components.dropLast().joined(separator: " ")
            return (last.uppercased(), given.isEmpty ? last.uppercased() : given.uppercased())
        }
        return (document.holderName.uppercased(), "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- TOP PAGE (Visas & Stamps) ---
            ZStack {
                // 1. CONTENT (Visible when open)
                ZStack {
                    Color(red: 0.98, green: 0.96, blue: 0.93) // Paper
                    
                    // A. Background Guilloche Waves (Subtle)
                    GeometryReader { geo in
                        Path { path in
                            for i in 0..<8 {
                                let y = CGFloat(i) * 35
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addCurve(
                                    to: CGPoint(x: geo.size.width, y: y),
                                    control1: CGPoint(x: geo.size.width / 3, y: y - 25),
                                    control2: CGPoint(x: geo.size.width * 2 / 3, y: y + 25)
                                )
                            }
                        }
                        .stroke(Color.blue.opacity(0.05), lineWidth: 1)
                    }
                    
                    // B. Center Watermark
                    Image(systemName: "globe.europe.africa.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130)
                        .foregroundColor(Color.blue.opacity(0.06))
                        .offset(y: 10)
                    
                    // C. Playful Stamps Layer
                    Group {
                        // Stamp 1: Blue Entry (LHR)
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "airplane.arrival")
                                Text("LHR")
                            }
                            .font(.system(size: 12, weight: .bold)) // Larger
                            
                            Text("18 AUG 2024")
                                .font(.system(size: 10, design: .monospaced)) // Larger
                            
                            Text("IMMIGRATION")
                                .font(.system(size: 7)) // Larger
                        }
                        .padding(8) // Larger padding
                        .overlay(
                            RoundedRectangle(cornerRadius: 6) // Larger radius
                                .stroke(Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.4), lineWidth: 2) // Dull
                        )
                        .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.4)) // Dull
                        .rotationEffect(.degrees(-15))
                        .offset(x: -85, y: -45) // Spaced out
                        
                        // Stamp 2: Red Exit (CDG)
                        ZStack {
                            Circle()
                                .stroke(Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.4), lineWidth: 2) // Dull
                                .frame(width: 75, height: 75) // Larger
                            
                            VStack(spacing: 1) {
                                Text("DEPARTURE")
                                    .font(.system(size: 7, weight: .black)) // Larger
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .bold)) // Larger
                                Text("CDG - PARIS")
                                    .font(.system(size: 8, weight: .bold)) // Larger
                            }
                            .foregroundColor(Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.4)) // Dull
                        }
                        .rotationEffect(.degrees(20))
                        .offset(x: 75, y: -30) // Spaced out
                        
                        // Stamp 3: Green Eco/Nature
                        VStack(spacing: 0) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14)) // Larger
                            Text("ECO CHECK")
                                .font(.system(size: 8, weight: .bold)) // Larger
                        }
                        .padding(8) // Larger
                        .overlay(
                            Capsule().stroke(Color.green.opacity(0.35), lineWidth: 1.5) // Dull
                        )
                        .foregroundColor(Color.green.opacity(0.35)) // Dull
                        .rotationEffect(.degrees(40))
                        .offset(x: -45, y: 70) // Spaced out
                        
                        // Stamp 4: Purple Playful Star
                        VStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10)) // Larger
                            Text("VISA")
                                .font(.system(size: 10, weight: .bold)) // Larger
                            Text("CLASS A")
                                .font(.system(size: 6)) // Larger
                        }
                        .padding(10) // Larger
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.purple.opacity(0.35), lineWidth: 2) // Dull
                        )
                        .foregroundColor(Color.purple.opacity(0.35)) // Dull
                        .rotationEffect(.degrees(-8))
                        .offset(x: 70, y: 60) // Spaced out
                    }
                    .compositingGroup() // Blend them together slightly
                    .opacity(0.7) // Overall duller
                    
                    // D. Header
                    VStack {
                        Text("VISAS")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .tracking(6)
                            .foregroundColor(.black.opacity(0.2))
                            .padding(.top, 12)
                        Spacer()
                    }
                }
                // Hide content when folded to prevent mirrored text issues
                // We animate opacity so it doesn't just disappear instanty
                .opacity(isOpen ? 1 : 0)
                
                // 2. OUTER COVER (Visible when folded)
                // This acts as the "back" of the top page, which is actually the FRONT COVER of the passport
                PassportCoverView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0)) // Flip texture to match fold
                    .opacity(isOpen ? 0 : 1)
            }
            // Inner Shadow for Spine Effect
            .overlay(
                LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 25),
                alignment: .bottom
            )
            .frame(height: 240) // Fixed Page Height
            .clipped() // FIX: Clip to frame AFTER frame is set
            // --- FOLD ANIMATION LOGIC ---
            // Anchor to the bottom (the spine)
            // When !isOpen, rotate 179 (fold FORWARD towards the viewer, covering bottom page)
            .rotation3DEffect(
                .degrees(isOpen ? 0 : 179),
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
            // Ensure this sits ON TOP of the bottom page when folded
            .zIndex(1)
            
            // --- SPINE ---
            // Only visible when open
            if isOpen {
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.93, blue: 0.90))
                    .frame(height: 2)
            }
            
            // --- BOTTOM PAGE (Data) ---
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                
                // Show photo if available
                if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // REMOVED fixed width to kill borders
                        .clipped()
                } else {
                    VStack(spacing: 0) {
                        // Header Bar
                        HStack {
                            Text(document.title.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            Spacer()
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.title3)
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        
                        Divider().background(Color.black).padding(.top, 8)
                        
                        Spacer() // VERTICAL CENTERING: Push content down
                        
                        // Data Page Layout
                        HStack(alignment: .center, spacing: 15) { // ALIGNMENT: Center vertical
                            // Photo Area
                            VStack {
                                ZStack {
                                    // 1. Photo Background with Gradient
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(white: 0.85), Color(white: 0.75)]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 110, height: 145) // Increased photo size
                                    
                                    // 2. Realistic Silhouette (Not Stretched)
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit) // Fix stretching
                                        .frame(width: 80) // Larger person icon
                                        .foregroundColor(Color(white: 0.4))
                                        .offset(y: 15) // Adjusted offset
                                    
                                    // 3. Border
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        .frame(width: 110, height: 145) // Match photo size
                                }
                                .clipped() // Ensure person doesn't spill out
                            }
                            
                            // Fields
                            VStack(alignment: .leading, spacing: 6) {
                                FieldView(label: "Type", value: "P")
                                // Use detailValue for Passport No
                                FieldView(label: "Passport No.", value: document.detailValue)
                                
                                // Split Name Logic
                                FieldView(label: "Surname", value: names.surname)
                                FieldView(label: "Given Names", value: names.given)
                                
                                // Nationality or Fallback to Title
                                FieldView(label: "Nationality", value: (document.nationality ?? document.title).uppercased())
                                
                                // Date of Birth
                                if let dob = document.birthDate {
                                    FieldView(label: "Date of Birth", value: dateFormatter.string(from: dob).uppercased())
                                } else {
                                    FieldView(label: "Date of Birth", value: "UNKNOWN")
                                }
                                
                                // Expiry
                                if let exp = document.expiryDate {
                                    FieldView(label: "Date of Expiry", value: dateFormatter.string(from: exp).uppercased())
                                }
                            }
                        }
                        .padding(.leading, 10) // ALIGNMENT: More to the left
                        .padding(.trailing, 15)
                        
                        Spacer() // VERTICAL CENTERING: Push content up
                        
                        // Machine Readable Zone (MRZ) - Simulated
                        VStack(spacing: 2) {
                            Text("P<\(String(document.title.prefix(3)).uppercased())\(names.surname)<<\(names.given.replacingOccurrences(of: " ", with: "<"))<<<<<<<<<<<<")
                            Text("\(document.detailValue.replacingOccurrences(of: " ", with: ""))\(String(document.title.prefix(3)).uppercased())<<<<<<<<<<<<<<<<<<04")
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                    }
                }
            }
            // Inner Shadow for Spine Effect
            .overlay(
                LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 25),
                alignment: .top
            )
            .frame(height: 240) // Fixed Page Height
            .clipped()
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - NEW: PASSPORT FLIP & FOLD ANIMATION
struct PassportFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    // 1. Controls the horizontal flip (0 = Front, 180 = Back)
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    // 2. Controls the vertical unfold (False = Folded, True = Open)
    @State private var isBookOpen = false
    
    var body: some View {
        ZStack {
            // BACK (Passport Interior)
            if isBackVisible {
                PassportInteriorView(document: document, isOpen: isBookOpen)
                    // Pre-rotate 180 on Y so it faces correctly when the card flips over
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            // FRONT (Card Cover)
            else {
                DocumentCardView(document: document)
            }
        }
        // Frame logic:
        // When selected, we want space for 2 pages (480) + padding.
        // We add a tiny bit of buffer (490) to prevent tight clipping around the spine
        .frame(height: isSelected ? 490 : 240)
        
        // MAIN FLIP ROTATION (Y-Axis)
        .rotation3DEffect(
            .degrees(yRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.8
        )
        .onTapGesture {
            onTap()
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                // SEQUENCE: OPENING
                
                // 1. Flip the card (Horizontal Coin Spin)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                
                // 1b. Swap the view halfway through the flip - Applied custom cubic-bezier
                withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.1).delay(0.15)) { // Short duration for a quick swap
                    isBackVisible = true
                }
                
                // 2. As the flip finishes, Unfold the book (Vertical Hinge)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.25)) {
                    isBookOpen = true
                }
                
            } else {
                // SEQUENCE: CLOSING
                
                // 1. Fold the book back up
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isBookOpen = false
                }
                
                // 2. Flip the card back over (after book is folded)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    yRotation = 0
                }
                
                // 2b. Swap view back to cover - Applied custom cubic-bezier
                withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.1).delay(0.45)) { // Delay matches the total delay from folding + flip
                    isBackVisible = false
                }
            }
        }
    }
}

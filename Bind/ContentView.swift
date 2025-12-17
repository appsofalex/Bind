import SwiftUI
import UIKit // Required for Color serialization helpers

// MARK: - 0. PERSISTENCE HELPERS

// A helper struct to make SwiftUI Color codable by storing RGBA components
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        // Convert SwiftUI Color to UIColor to extract components (iOS 14+)
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// Manages saving and loading from the Documents directory
class TravelDocumentStore {
    static let shared = TravelDocumentStore()
    private let fileName = "travel_docs_v1.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    func load() -> [TravelDocument] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([TravelDocument].self, from: data)
            return decoded
        } catch {
            // Return empty array on first launch (no file exists)
            return []
        }
    }
    
    func save(_ docs: [TravelDocument]) {
        do {
            let data = try JSONEncoder().encode(docs)
            try data.write(to: fileURL)
        } catch {
            print("Error saving documents: \(error)")
        }
    }
}

// MARK: - 1. DATA MODELS
struct TravelDocument: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let type: DocumentType
    let title: String
    let subtitle: String
    let holderName: String
    let detailValue: String
    
    // NEW FIELDS (Optional to maintain backward compatibility with JSON)
    var nationality: String?
    var birthDate: Date?
    var issueDate: Date?
    var expiryDate: Date?
    
    // Internal storage for Codable colors
    private let primaryColorData: CodableColor
    private let secondaryColorData: CodableColor
    
    let iconName: String
    let airline: String 
    var isActive: Bool = true // Toggle state property
    
    // Public computed properties for View usage
    var primaryColor: Color { primaryColorData.color }
    var secondaryColor: Color { secondaryColorData.color }
    
    // Custom Initializer to handle Color -> Codable conversion transparently
    init(id: UUID = UUID(), 
         type: DocumentType, 
         title: String, 
         subtitle: String, 
         holderName: String, 
         detailValue: String,
         nationality: String? = nil,
         birthDate: Date? = nil,
         issueDate: Date? = nil,
         expiryDate: Date? = nil,
         primaryColor: Color, 
         secondaryColor: Color, 
         iconName: String, 
         airline: String, 
         isActive: Bool = true) {
        
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.holderName = holderName
        self.detailValue = detailValue
        self.nationality = nationality
        self.birthDate = birthDate
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.primaryColorData = CodableColor(color: primaryColor)
        self.secondaryColorData = CodableColor(color: secondaryColor)
        self.iconName = iconName
        self.airline = airline
        self.isActive = isActive
    }
    
    enum DocumentType: String, CaseIterable, Identifiable, Codable {
        case passport, visa, boardingPass, insurance, idCard
        // NEW TYPES
        case driversLicense, studentID, prescription, vaccineRecord, medicalAlert
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .driversLicense: return "Driver's License"
            case .studentID: return "Student ID"
            case .prescription: return "Prescription"
            case .vaccineRecord: return "Vaccination Record"
            case .medicalAlert: return "Medical Alert"
            case .idCard: return "ID Card"
            case .boardingPass: return "Boarding Pass"
            default: return rawValue.capitalized
            }
        }
    }
}

// MARK: - 2. THE CARD VIEW (Front Cover used in Wallet Stack)
struct DocumentCardView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // Solid backing to prevent transparency (see-through to other cards)
            Color.black
            
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [document.primaryColor, document.primaryColor.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Texture Icon
            Image(systemName: document.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300)
                .position(x: 300, y: 100)
                .opacity(0.1)
                .blur(radius: 2)
                .foregroundColor(.white)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: document.iconName)
                        .font(.title2)
                        .foregroundColor(document.secondaryColor)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text(document.subtitle)
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(document.secondaryColor.opacity(0.8))
                }
                
                Spacer()
                
                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(document.title)
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1) // Prevents text overflow
                        .minimumScaleFactor(0.8) // Shrinks text if title is too long
                    
                    Text(document.holderName)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Footer
                HStack {
                    Text(document.detailValue)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(document.secondaryColor)
                    
                    Spacer()
                    
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(25)
        }
        .frame(height: 240) // Fixed height for the card look
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        // Ensure the entire frame is tappable (fixing the gap/corner issue)
        .contentShape(Rectangle())
    }
}

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

struct FieldView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.system(size: 8))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
        }
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
                
                // 1b. Swap the view halfway through the flip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                }
                
                // 2. As the flip finishes, Unfold the book (Vertical Hinge)
                // We delay slightly so the book "pops" open just as it faces the user
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
                
                // 2b. Swap view back to cover
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isBackVisible = false
                }
            }
        }
    }
}

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
    
    var body: some View {
        
        let brandColor = getAirlineColor(name: document.airline)
        
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
                    Text("ONEWORLD")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                // Use brand color for header
                .background(brandColor)
                
                // 2. Flight Path Animation Area
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("LHR")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.black)
                            Text("LONDON")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("HND")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.black)
                            Text("TOKYO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
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
                        FieldView(label: "FLIGHT", value: document.detailValue)
                        FieldView(label: "DATE", value: "14 OCT")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FieldView(label: "BOARDING", value: "10:20")
                        FieldView(label: "GATE", value: "B42")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FieldView(label: "SEAT", value: "4A")
                        FieldView(label: "CLASS", value: "BUSINESS")
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


// MARK: - NEW: ID CARD DETAIL (Back of ID Card)
struct IDCardDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            // Plastic Card Background
            Color(white: 0.95)
            
            // Decorative guilloche patterns (simplified as opacity circles)
            Circle()
                .stroke(document.primaryColor.opacity(0.1), lineWidth: 20)
                .offset(x: -50, y: -50)
            Circle()
                .stroke(document.primaryColor.opacity(0.1), lineWidth: 20)
                .offset(x: 100, y: 100)
            
            VStack(spacing: 0) {
                // Header Strip
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(document.primaryColor)
                        .font(.caption2)
                    Text("REPUBLIC OF IDENTITY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(document.primaryColor)
                        .tracking(1)
                    Spacer()
                    Image(systemName: "star.circle")
                        .foregroundColor(document.primaryColor)
                        .font(.caption2)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(document.primaryColor.opacity(0.1))
                
                // Main Content
                HStack(alignment: .top, spacing: 12) {
                    // Photo
                    VStack {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 75, height: 95)
                                .cornerRadius(4)
                            Image(systemName: "person.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 15)
                    .padding(.top, 8)
                    
                    // Fields
                    VStack(alignment: .leading, spacing: 5) {
                        FieldView(label: "Surname", value: "WALTERS")
                        FieldView(label: "Given Names", value: "ALEXANDER")
                        FieldView(label: "Date of Birth", value: "12 JUN 1985")
                        FieldView(label: "Document No.", value: document.detailValue)
                        FieldView(label: "Expires", value: "12 JUN 2030")
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Bottom Machine Readable Zone
                VStack(alignment: .leading, spacing: 1) {
                    Text("I<UTOWALTERS<<ALEXANDER<<<<<<<<<<<<")
                    Text("9928828UTO8506126M3006126<<<<<<<04")
                    Text("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                }
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.black.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white)
            }
        }
        .frame(height: 240)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - NEW: ID CARD FLIP ANIMATION
struct IDFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            // BACK (Detail View)
            if isBackVisible {
                IDCardDetailView(document: document)
                    // Pre-rotate 180 so it's correct when flipped
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } 
            // FRONT (Cover)
            else {
                DocumentCardView(document: document)
            }
        }
        .frame(height: 240) // Standard height, no expansion
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
                // FLIP OPEN
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                }
            } else {
                // FLIP CLOSE
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

// MARK: - NEW: EMPTY WALLET VIEW (Extracted for reliable animation reset)
struct EmptyWalletView: View {
    @State private var animateArrow = false
    
    var body: some View {
        ZStack {
            // Text Content
            VStack(spacing: 15) {
                Spacer()
                
                Image(systemName: "wallet.pass")
                    .font(.system(size: 70))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.bottom, 10)
                
                Text("No Cards Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Add your first document or booking to get started.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                
                Spacer()
                    .frame(height: 100)
                
                Spacer()
            }
            .zIndex(0)
            
            // Animated Pointing Arrow
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.right") // Using the curved arrow
                        .font(.system(size: 35, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(45))
                        // Animate position: Move left to right horizontally
                        .offset(x: animateArrow ? 15 : -15, y: 0)
                        .position(x: geo.size.width - 95, y: 71)
                }
            }
            .zIndex(1)
        }
        .onAppear {
            animateArrow = false // Reset state
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                animateArrow = true
            }
        }
    }
}

// MARK: - 3. MAIN WALLET VIEW
struct TravelDocsWalletView: View {
    // Selection State
    @State private var selectedID: UUID? = nil
    
    // DATA STATE (Loads from disk on init)
    @State private var documents: [TravelDocument] = TravelDocumentStore.shared.load()
    
    // ADD MENU STATE
    @State private var showAllCardsSheet = false
    @State private var selectedTypeToAdd: TravelDocument.DocumentType? = nil
    
    // EDIT STATE
    @State private var documentToEdit: TravelDocument? = nil
    
    // Scroll/Drag State
    @AppStorage("walletScrollOffset") private var baseScrollOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    
    // Configuration
    private let cardSpacing: CGFloat = 65
    private let maxCardsOnScreen = 6
    
    // MARK: - NEW: ONLY SHOW ACTIVE CARDS (Max 6 handled by toggles)
    var activeDocuments: [TravelDocument] {
        documents.filter { $0.isActive }
    }
    
    private var totalScrollHeight: CGFloat {
        CGFloat(activeDocuments.count) * cardSpacing
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            
            // MARK: - NEW: EMPTY STATE
            if documents.isEmpty {
                EmptyWalletView()
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            // MARK: - 1. MAIN CARD AREA (Now Full Screen Background)
            GeometryReader { geo in
                ZStack(alignment: .center) {
                    ForEach(Array(activeDocuments.enumerated()), id: \.element.id) { index, doc in
                        
                        // 1. CALCULATE DYNAMIC POSITION
                        let currentPos = getCircularPosition(for: index)
                        let isPassport = (doc.type == .passport)
                        // CHANGED: Group generic ID types together for the flip animation
                        let isIDCard = (doc.type == .idCard || doc.type == .driversLicense || doc.type == .studentID)
                        let isBoardingPass = (doc.type == .boardingPass)
                        let isSelected = (selectedID == doc.id)
                        
                        Group {
                            if isPassport {
                                // Use the specialized flip card for Passport
                                PassportFlipCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isIDCard {
                                // Use specialized flip card for ID
                                IDFlipCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isBoardingPass {
                                // Use specialized animation for Boarding Pass
                                BoardingPassAnimatedCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else {
                                // Standard cards for new types
                                DocumentCardView(document: doc)
                                    .onTapGesture { toggleSelection(for: doc.id) }
                            }
                        }
                        .frame(width: geo.size.width - 40)
                        
                        // 2. POSITIONING & DEPTH
                        .scaleEffect(getScale(for: currentPos, docID: doc.id))
                        .rotation3DEffect(
                            .degrees(getRotation(for: currentPos, docID: doc.id)),
                            axis: (x: 1, y: 0, z: 0)
                        )
                        .offset(y: getOffset(for: currentPos, docID: doc.id))
                        
                        // 3. STACK ORDER (Z-Index)
                        .zIndex(getZIndex(for: currentPos, docID: doc.id))
                        
                        // Animation value
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: selectedID)
                        
                        // DELETE ANIMATION (Fly off to right)
                        .transition(
                            .asymmetric(
                                insertion: .identity,
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // 5. DRAG GESTURE (THE ROLODEX)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard selectedID == nil else { return }
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            guard selectedID == nil else { return }
                            
                            let totalDrag = CGFloat(baseScrollOffset) + value.translation.height
                            let velocity = value.predictedEndTranslation.height / 5
                            let projectedTotal = totalDrag + velocity
                            
                            let snapStep = cardSpacing
                            let nearestStep = (projectedTotal / snapStep).rounded() * snapStep
                            
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                baseScrollOffset = Double(nearestStep)
                                dragOffset = 0
                            }
                        }
                )
            }
            
            // MARK: - 2. PERSISTENT HEADER (Overlay)
            // Sits on top of cards so it doesn't push them down
            VStack {
                HStack {
                    if selectedID == nil {
                        Text("Bind")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.opacity)
                    } else {
                        // Invisible text to maintain height
                         Text("Bind")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .opacity(0)
                    }
                    
                    Spacer()
                    
                    if selectedID == nil {
                        // NEW: Native Plus Menu with Dropdown Options
                        Menu {
                            Section("Travel") {
                                Button(action: { startAdd(.passport) }) { Label("Passport", systemImage: "globe") }
                                Button(action: { startAdd(.boardingPass) }) { Label("Boarding Pass", systemImage: "airplane") }
                                Button(action: { startAdd(.visa) }) { Label("Visa", systemImage: "checkmark.seal") }
                                Button(action: { startAdd(.insurance) }) { Label("Insurance", systemImage: "cross.case") }
                            }
                            Section("Identity") {
                                Button(action: { startAdd(.driversLicense) }) { Label("Driver's License", systemImage: "car") }
                                Button(action: { startAdd(.studentID) }) { Label("Student ID", systemImage: "graduationcap") }
                                Button(action: { startAdd(.idCard) }) { Label("National ID", systemImage: "person.text.rectangle") }
                            }
                            
                            Section("Health") {
                                Button(action: { startAdd(.prescription) }) { Label("Prescription", systemImage: "pills") }
                                Button(action: { startAdd(.vaccineRecord) }) { Label("Vaccination Record", systemImage: "syringe") }
                                Button(action: { startAdd(.medicalAlert) }) { Label("Blood & Allergies", systemImage: "staroflife") }
                            }

                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32)) // Slightly larger touch target
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle())) // Match ellipsis style
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // MARK: - DELETE BUTTON (Ellipsis Menu)
                        // Shows when a card is selected
                        if let doc = documents.first(where: { $0.id == selectedID }) {
                            Menu {
                                // EDIT BUTTON
                                Button {
                                    documentToEdit = doc
                                } label: {
                                    Label("Edit Card", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteDocument(doc)
                                } label: {
                                    Label("Remove Card", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.system(size: 32))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.5).clipShape(Circle()))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50) // Adjust for notch
                
                Spacer() // Pushes header to top
            }
            // Ensure header doesn't block card touches in empty space
            .allowsHitTesting(true)
            
            // MARK: - NEW: OVERFLOW BUTTON (If > 6 cards OR user wants to edit)
            // Changed logic: Always show if there are documents
            if !documents.isEmpty && selectedID == nil {
                VStack {
                    Spacer()
                    Button(action: {
                        showAllCardsSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("All Cards")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Close Button (Only visible when card selected)
            if selectedID != nil {
                VStack {
                    Spacer()
                    Button(action: {
                        toggleSelection(for: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
                .zIndex(200)
            }
        }
        // AUTOMATIC SAVING: Whenever documents array changes, save to disk
        .onChange(of: documents) { newValue in
            TravelDocumentStore.shared.save(newValue)
        }
        // ADD SHEET: Triggers when the user selects an item from the Menu
        .sheet(item: $selectedTypeToAdd) { type in
            AddDocumentView(type: type) { newDoc in
                withAnimation {
                    // 1. If we are at max capacity (6), deactivate the last active card to make room
                    if activeDocuments.count >= maxCardsOnScreen {
                        // Find the index of the last active card
                        if let lastActiveIndex = documents.lastIndex(where: { $0.isActive }) {
                            documents[lastActiveIndex].isActive = false
                        }
                    }
                    
                    // 2. Insert new card at top (it is active by default)
                    documents.insert(newDoc, at: 0)
                    
                    // 3. Reset scroll so the top (0th item) is front-and-center
                    baseScrollOffset = 0
                    dragOffset = 0
                }
            }
        }
        // EDIT SHEET: Triggers when user taps "Edit"
        .sheet(item: $documentToEdit) { doc in
            AddDocumentView(document: doc) { updatedDoc in
                // Update the document in place
                if let index = documents.firstIndex(where: { $0.id == updatedDoc.id }) {
                    documents[index] = updatedDoc
                }
            }
        }
        // MARK: - NEW: ALL CARDS SHEET WITH TOGGLES
        .sheet(isPresented: $showAllCardsSheet) {
            NavigationView {
                List {
                    ForEach($documents) { $doc in
                        HStack(spacing: 15) {
                            Image(systemName: doc.iconName)
                                .font(.title2)
                                .foregroundColor(doc.primaryColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(doc.title)
                                    .font(.headline)
                                Text(doc.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // Native Switch
                            Toggle("", isOn: $doc.isActive)
                                .labelsHidden()
                                .tint(.green)
                                // Disable turning ON if we are already at 6
                                .disabled(!doc.isActive && activeDocuments.count >= maxCardsOnScreen)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        documents.remove(atOffsets: indexSet)
                    }
                }
                .navigationTitle("All Cards (\(activeDocuments.count)/\(maxCardsOnScreen))")
                .navigationBarItems(trailing: Button("Done") { showAllCardsSheet = false })
            }
        }
    }
    
    // MARK: - LOGIC
    
    func deleteDocument(_ doc: TravelDocument) {
        // Trigger Animation: Remove card from array
        // The .transition(.move(edge: .trailing)) on the view handles the visual "fly off"
        withAnimation(.easeInOut(duration: 0.35)) {
            if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                documents.remove(at: index)
            }
            // Clear selection state after removal starts
            selectedID = nil
        }
    }
    
    func startAdd(_ type: TravelDocument.DocumentType) {
        selectedTypeToAdd = type
    }
    
    func toggleSelection(for id: UUID?) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if let id = id, selectedID == id {
                selectedID = nil
            } else {
                selectedID = id
            }
        }
    }
    
    // --- ROLODEX MATH ---
    
    // Calculates where the card is in the loop (0 to totalScrollHeight)
    func getCircularPosition(for index: Int) -> CGFloat {
        // SAFETY: Avoid crash if all documents are deleted
        if totalScrollHeight == 0 { return 0 }
        
        let initialOffset = CGFloat(index) * cardSpacing
        let currentScroll = CGFloat(baseScrollOffset) + dragOffset
        
        // Combine index offset with scroll
        let rawPosition = initialOffset + currentScroll
        
        // Modulo arithmetic to wrap values
        let loopedPosition = rawPosition.truncatingRemainder(dividingBy: totalScrollHeight)
        
        if loopedPosition < 0 {
            return loopedPosition + totalScrollHeight
        } else {
            return loopedPosition
        }
    }
    
    func getOffset(for position: CGFloat, docID: UUID) -> CGFloat {
        if let selected = selectedID {
            // Return to 0 for true center
            return selected == docID ? 0 : 1000 
        }
        
        // FIX: Center the stack based on the number of actual cards, not the scroll loop.
        // We calculate the midpoint of the card distribution: ((Count - 1) * Spacing) / 2
        let count = CGFloat(activeDocuments.count)
        let stackCenterAdjustment = count > 1 ? ((count - 1) * cardSpacing) / 2 : 0
        
        return position - stackCenterAdjustment
    }
    
    func getScale(for position: CGFloat, docID: UUID) -> CGFloat {
        if let selected = selectedID {
            return selected == docID ? 1.0 : 0.8
        }
        let progress = position / totalScrollHeight
        return 0.85 + (0.15 * progress)
    }
    
    func getRotation(for position: CGFloat, docID: UUID) -> Double {
        if selectedID != nil { return 0 }
        let progress = position / totalScrollHeight
        return -10 * (1 - progress)
    }
    
    func getZIndex(for position: CGFloat, docID: UUID) -> Double {
        if let selected = selectedID, selected == docID {
            return Double(totalScrollHeight) + 100 // Ensure selected card is always on top
        }
        return Double(position)
    }
}

// MARK: - NEW: ADD DOCUMENT VIEW & FORM
struct AddDocumentView: View {
    let type: TravelDocument.DocumentType
    let onAdd: (TravelDocument) -> Void
    let existingID: UUID? // Stores ID if we are editing
    
    @Environment(\.dismiss) var dismiss
    
    // Form Fields
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var holderName: String = ""
    @State private var detailValue: String = ""
    
    // Specific Dropdowns
    @State private var selectedBloodType = "A+"
    @State private var selectedAllergy = "None"
    @State private var selectedVaccine = "COVID-19"
    @State private var selectedUniversity = "State Univ"
    @State private var selectedAirline = "British Airways"
    
    // PASSPORT SPECIFIC FIELDS
    @State private var nationality: String = ""
    @State private var birthDate: Date = Date()
    @State private var issueDate: Date = Date()
    @State private var expiryDate: Date = Date()
    
    let bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let vaccines = ["COVID-19", "Influenza", "Yellow Fever", "Tetanus", "Hepatitis B", "Measles"]
    
    // MARK: - NEW: COUNTRY DATA
    let countries = [
        "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan",
        "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
        "Cabo Verde", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo (Congo-Brazzaville)", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czechia",
        "Denmark", "Djibouti", "Dominica", "Dominican Republic",
        "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia",
        "Fiji", "Finland", "France",
        "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana",
        "Haiti", "Honduras", "Hungary",
        "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy",
        "Jamaica", "Japan", "Jordan",
        "Kazakhstan", "Kenya", "Kiribati", "Kuwait", "Kyrgyzstan",
        "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg",
        "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar",
        "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Korea", "North Macedonia", "Norway",
        "Oman",
        "Pakistan", "Palau", "Palestine State", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal",
        "Qatar",
        "Romania", "Russia", "Rwanda",
        "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria",
        "Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu",
        "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
        "Vanuatu", "Venezuela", "Vietnam",
        "Yemen",
        "Zambia", "Zimbabwe"
    ]
    
    // Segmented Airlines by Country
    let airlineSegments: [(country: String, airlines: [String])] = [
        ("United Kingdom", ["British Airways", "easyJet", "Virgin Atlantic"]),
        ("United States", ["American Airlines", "Delta", "United"]),
        ("Australia", ["Qantas"]),
        ("Canada", ["Air Canada"]),
        ("China", ["Air China"]),
        ("Germany", ["Lufthansa"]),
        ("Ireland", ["Ryanair"]),
        ("Japan", ["Japan Airlines"]),
        ("Qatar", ["Qatar Airways"]),
        ("Singapore", ["Singapore Airlines"]),
        ("UAE", ["Emirates"])
    ]
    
    // MARK: - NEW: AIRPORT DATA
    let airports = [
        ("ATL", "Hartsfield-Jackson Atlanta"),
        ("JFK", "New York John F. Kennedy"),
        ("LAX", "Los Angeles International"),
        ("ORD", "Chicago O'Hare"),
        ("DFW", "Dallas/Fort Worth"),
        ("DEN", "Denver International"),
        ("SFO", "San Francisco International"),
        ("YYZ", "Toronto Pearson"),
        ("YVR", "Vancouver International"),
        ("LHR", "London Heathrow"),
        ("LGW", "London Gatwick"),
        ("LTN", "London Luton"),
        ("STN", "London Stansted"),
        ("LCY", "London City"),
        ("SEN", "London Southend"),
        ("MAN", "Manchester"),
        ("EDI", "Edinburgh"),
        ("BRS", "Bristol"),
        ("CDG", "Paris Charles de Gaulle"),
        ("AMS", "Amsterdam Schiphol"),
        ("FRA", "Frankfurt Airport"),
        ("IST", "Istanbul Airport"),
        ("MAD", "Madrid-Barajas"),
        ("DXB", "Dubai International"),
        ("DOH", "Doha Hamad International"),
        ("AUH", "Abu Dhabi International"),
        ("HND", "Tokyo Haneda"),
        ("NRT", "Tokyo Narita"),
        ("HKG", "Hong Kong International"),
        ("SIN", "Singapore Changi"),
        ("ICN", "Seoul Incheon"),
        ("PEK", "Beijing Capital"),
        ("PVG", "Shanghai Pudong"),
        ("BKK", "Bangkok Suvarnabhumi"),
        ("DEL", "Delhi Indira Gandhi"),
        ("SYD", "Sydney Kingsford Smith"),
        ("MEL", "Melbourne Tullamarine"),
        ("AKL", "Auckland Airport"),
        ("GRU", "São Paulo Guarulhos"),
        ("BOG", "El Dorado International"),
        ("JNB", "O.R. Tambo Johannesburg"),
        ("CAI", "Cairo International"),
        ("MUC", "Munich"),
        ("ZRH", "Zurich"),
        ("VIE", "Vienna"),
        ("DUB", "Dublin"),
        ("BCN", "Barcelona El Prat"),
        ("FCO", "Rome Fiumicino"),
        ("MXP", "Milan Malpensa"),
        ("LIN", "Milan Linate"),
        ("LIS", "Lisbon"),
        ("CPH", "Copenhagen"),
        ("ARN", "Stockholm Arlanda"),
        ("OSL", "Oslo Gardermoen"),
        ("HEL", "Helsinki"),
        ("WAW", "Warsaw Chopin"),
        ("ATH", "Athens"),
        ("BUD", "Budapest"),
        ("PRG", "Prague"),
        ("FAO", "Faro"),
        ("NCE", "Nice"),
        ("ALC", "Alicante"),
        ("PMI", "Palma de Mallorca")
    ]
    // MARK: - NEW: AIRPORT FILTER LOGIC
    // CHANGED: Returns tuples instead of strings to allow custom layout in the menu
    var filteredAirports: [(code: String, name: String)] {
        if title.isEmpty { return [] }
        
        // 1. Find matches
        let matches = airports.filter { code, name in
            code.localizedCaseInsensitiveContains(title) || name.localizedCaseInsensitiveContains(title)
        }
        
        // 2. Hide suggestions if the user has already selected a valid full entry
        // We check if the current `title` matches a fully formatted string from our data
        // Format used in selection: "Name (Code)"
        if matches.contains(where: { "\( $0.1 ) (\( $0.0 ))" == title }) {
            return []
        }
        
        // 3. Sort alphabetically by name
        return matches.sorted { $0.1 < $1.1 }.map { (code: $0.0, name: $0.1) }
    }
    
    // Initialize default values based on type OR existing document
    init(type: TravelDocument.DocumentType? = nil, 
         document: TravelDocument? = nil, 
         onAdd: @escaping (TravelDocument) -> Void) {
        
        self.onAdd = onAdd
        
        if let doc = document {
            // EDIT MODE
            self.type = doc.type
            self.existingID = doc.id
            
            _title = State(initialValue: doc.title)
            _subtitle = State(initialValue: doc.subtitle)
            _holderName = State(initialValue: doc.holderName)
            _detailValue = State(initialValue: doc.detailValue)
            _nationality = State(initialValue: doc.nationality ?? "")
            
            if let dob = doc.birthDate { _birthDate = State(initialValue: dob) }
            if let iss = doc.issueDate { _issueDate = State(initialValue: iss) }
            if let exp = doc.expiryDate { _expiryDate = State(initialValue: exp) }
            
            // Try to pre-fill airline if it exists in our segments (mostly visual)
            if !doc.airline.isEmpty {
                _selectedAirline = State(initialValue: doc.airline)
            }
            
        } else {
            // ADD MODE
            let targetType = type ?? .passport
            self.type = targetType
            self.existingID = nil
            
            // Defaults
            switch targetType {
            case .passport:
                // Default country
                _title = State(initialValue: "United Kingdom")
                _nationality = State(initialValue: "United Kingdom")
            case .driversLicense:
                _title = State(initialValue: "California")
                _subtitle = State(initialValue: "DRIVER LICENSE")
            case .studentID:
                _title = State(initialValue: "University")
                _subtitle = State(initialValue: "STUDENT ID")
            case .prescription:
                _title = State(initialValue: "Pharmacy")
                _subtitle = State(initialValue: "RX PRESCRIPTION")
            case .vaccineRecord:
                _title = State(initialValue: "CDC / NHS")
                _subtitle = State(initialValue: "VACCINATION")
            case .medicalAlert:
                _title = State(initialValue: "Medical Alert")
                _subtitle = State(initialValue: "EMERGENCY INFO")
            default:
                break
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    // Context-aware fields
                    if type == .medicalAlert {
                        Picker("Blood Type", selection: $selectedBloodType) {
                            ForEach(bloodTypes, id: \.self) { Text($0) }
                        }
                        TextField("Allergies", text: $holderName) // Using holderName for Allergy list
                            .overlay(
                                Text("e.g. Peanuts, Penicillin").foregroundColor(.gray.opacity(0.5)).allowsHitTesting(false).opacity(holderName.isEmpty ? 1 : 0),
                                alignment: .leading
                            )
                    } else if type == .vaccineRecord {
                         Picker("Vaccine Type", selection: $selectedVaccine) {
                             ForEach(vaccines, id: \.self) { Text($0) }
                         }
                         TextField("Date / Dose", text: $detailValue)
                    } else if type == .boardingPass {
                         Picker("Airline", selection: $selectedAirline) {
                             ForEach(airlineSegments, id: \.country) { segment in
                                 Section(header: Text(segment.country)) {
                                     ForEach(segment.airlines, id: \.self) { airline in
                                         Text(airline).tag(airline)
                                     }
                                 }
                             }
                         }
                         
                         // MARK: - NEW: AUTOCOMPLETE AIRPORT FIELD
                         TextField("Destination (Type code or city)", text: $title)
                         
                         // Show suggestions if typing matches
                         if !filteredAirports.isEmpty {
                             ForEach(filteredAirports, id: \.code) { airport in
                                 Button(action: {
                                     // Set formatted title when selected
                                     title = "\(airport.name) (\(airport.code))"
                                 }) {
                                     // CHANGED: Custom layout for the menu row
                                     HStack {
                                         Text(airport.name)
                                             .foregroundColor(.primary)
                                         Spacer()
                                         Text(airport.code)
                                             .font(.system(.subheadline, design: .monospaced))
                                             .fontWeight(.bold)
                                             .foregroundColor(.gray)
                                     }
                                 }
                             }
                         }
                    } else if type == .passport {
                        // MARK: - NEW: PASSPORT COUNTRY PICKER
                        Picker("Country", selection: $title) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        // Auto-update Nationality when Country changes
                        .onChange(of: title) { newValue in
                            nationality = newValue
                        }
                        // No subtitle field for passport
                        
                    } else {
                        TextField("Title (e.g. Country, State)", text: $title)
                        TextField("Subtitle (e.g. License Type)", text: $subtitle)
                    }
                }
                
                Section(header: Text("Personal Info")) {
                    if type == .medicalAlert {
                        // Already handled allergies above, use this for Emergency Contact
                        TextField("Emergency Contact", text: $detailValue)
                    } else if type == .passport {
                        // MARK: - SPECIFIC PASSPORT FIELDS
                        TextField("Full Name", text: $holderName)
                        TextField("Passport Number", text: $detailValue)
                        TextField("Nationality", text: $nationality) // Auto-filled but editable
                        
                        DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                        DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)
                    } else {
                        TextField("Your Name", text: $holderName)
                        TextField("Booking Number", text: $detailValue)
                    }
                }
            }
            .navigationTitle(existingID != nil ? "Edit \(type.displayName)" : "Add \(type.displayName)")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(existingID != nil ? "Save" : "Add") {
                    saveDocument()
                    dismiss()
                }
            )
        }
    }
    
    func saveDocument() {
        // Construct the document based on type-specific logic
        
        var finalTitle = title
        var finalSubtitle = subtitle
        var finalHolder = holderName
        var finalDetail = detailValue
        var finalAirline = ""
        
        // Custom Construction Logic
        switch type {
        case .medicalAlert:
            finalTitle = "Medical Alert"
            finalSubtitle = "BLOOD / ALLERGY"
            finalHolder = "TYPE: \(selectedBloodType)" // Store Blood Type in Holder slot
            // finalDetail holds Emergency Contact or Allergies
            
        case .vaccineRecord:
            finalTitle = "Vaccination"
            finalSubtitle = selectedVaccine.uppercased()
            // finalHolder is Name
            // finalDetail is Date
            
        case .boardingPass:
            finalAirline = selectedAirline
            
        default:
            break
        }
        
        // Defaults if empty
        if finalTitle.isEmpty { finalTitle = "New Document" }
        // NEW: Ensure subtitle defaults to the document type name if not set manually
        if finalSubtitle.isEmpty { finalSubtitle = type.displayName.uppercased() }
        if finalHolder.isEmpty { finalHolder = "CARD HOLDER" }
        
        let newDoc = TravelDocument(
            id: existingID ?? UUID(), // Preserve ID if editing
            type: type,
            title: finalTitle,
            subtitle: finalSubtitle,
            holderName: finalHolder,
            detailValue: finalDetail,
            nationality: type == .passport ? nationality : nil,
            birthDate: type == .passport ? birthDate : nil,
            issueDate: type == .passport ? issueDate : nil,
            expiryDate: type == .passport ? expiryDate : nil,
            primaryColor: getColor(for: type),
            secondaryColor: .white,
            iconName: getIcon(for: type),
            airline: finalAirline
        )
        
        onAdd(newDoc)
    }
    
    func getColor(for type: TravelDocument.DocumentType) -> Color {
        switch type {
        case .driversLicense: return Color(red: 0.2, green: 0.3, blue: 0.45) // Slate Blue
        case .studentID: return Color(red: 0.5, green: 0.1, blue: 0.1) // Maroon
        case .prescription: return Color(red: 0.0, green: 0.6, blue: 0.45) // Pharmacy Teal
        case .vaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7) // Health Blue
        case .medicalAlert: return Color(red: 0.85, green: 0.2, blue: 0.2) // Alert Red
        case .passport: return Color(red: 0.05, green: 0.05, blue: 0.25)
        case .boardingPass: return Color(red: 1.0, green: 0.31, blue: 0.0)
        case .visa: return Color(red: 0.85, green: 0.2, blue: 0.3)
        case .insurance: return Color(red: 0.0, green: 0.5, blue: 0.5)
        case .idCard: return Color(red: 0.45, green: 0.2, blue: 0.6)
        }
    }
    
    func getIcon(for type: TravelDocument.DocumentType) -> String {
        switch type {
        case .driversLicense: return "car.fill"
        case .studentID: return "graduationcap.fill"
        case .prescription: return "pills.fill"
        case .vaccineRecord: return "syringe.fill"
        case .medicalAlert: return "staroflife.fill"
        case .passport: return "globe"
        case .boardingPass: return "airplane"
        case .visa: return "checkmark.seal"
        case .insurance: return "cross.fill"
        case .idCard: return "person.text.rectangle.fill"
        }
    }
}
struct Bind_Previews: PreviewProvider {
    static var previews: some View {
        TravelDocsWalletView()
            .preferredColorScheme(.dark)
    }
}


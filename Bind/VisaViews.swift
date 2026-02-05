import SwiftUI

// MARK: - VISA COVER VIEW
struct VisaCoverView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            document.primaryColor
            
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("VISA")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                    .tracking(8)
                
                Text(document.title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Image(systemName: "hand.raised.fill") // Security symbol
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - VISA INTERIOR VIEW
struct VisaInteriorView: View {
    let document: TravelDocument
    let isOpen: Bool
    
    // Date Formatter Helper
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // TOP PAGE (Security Features & Title)
            ZStack {
                // 1. CONTENT (Visible when open)
                ZStack {
                    Color(red: 0.95, green: 0.98, blue: 0.95) // Light greenish paper
                    
                    // Guilloche Pattern (Subtle)
                    GeometryReader { geo in
                        Path { path in
                            for i in 0..<10 {
                                let y = CGFloat(i) * 25
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addCurve(
                                    to: CGPoint(x: geo.size.width, y: y),
                                    control1: CGPoint(x: geo.size.width / 4, y: y + 30),
                                    control2: CGPoint(x: geo.size.width * 3 / 4, y: y - 30)
                                )
                            }
                        }
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                    }
                    
                    VStack(spacing: 10) {
                        Text("VISA")
                            .font(.system(size: 30, weight: .black, design: .serif))
                            .tracking(10)
                            .foregroundColor(.green.opacity(0.2))
                        
                        Image(systemName: "seal.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green.opacity(0.1))
                    }
                    
                    // Content Overlay
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Issuing Authority")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.issuingAuthority ?? "OFFICIAL")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Entries")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.entries?.uppercased() ?? "SINGLE")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                        .padding(20)
                        Spacer()
                        
                        if let remarks = document.visaRemarks, !remarks.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remarks / Annotations")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(remarks)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(3)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .opacity(isOpen ? 1 : 0)

                // 2. OUTER COVER (Visible when folded)
                VisaCoverView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                    .opacity(isOpen ? 0 : 1)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 25)
                    .opacity(isOpen ? 1 : 0),
                alignment: .bottom
            )
            .rotation3DEffect(
                .degrees(isOpen ? 0 : 179),
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
            .zIndex(1)
            
            // BOTTOM PAGE (Personal Data)
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.95) // Off-white paper
                
                VStack(spacing: 0) {
                    // Data Section
                    HStack(alignment: .top, spacing: 15) {
                        // Profile Image Placeholder
                        VStack {
                            ZStack {
                                Rectangle()
                                    .fill(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 100, height: 130)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 70)
                                    .foregroundColor(.white)
                                    .offset(y: 10)
                                
                                // Holographic Overlay
                                Image(systemName: "sparkles")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.1))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.1), lineWidth: 1))
                        }
                        .padding(.leading, 15)
                        .padding(.top, 20)
                        
                        // Fields
                        VStack(alignment: .leading, spacing: 8) {
                            FieldView(label: "Surname / Given Names", value: document.holderName.uppercased())
                            
                            HStack(spacing: 20) {
                                FieldView(label: "Visa Number", value: document.detailValue)
                                FieldView(label: "Passport No.", value: document.passportNumber ?? "UNKNOWN")
                            }
                            
                            HStack(spacing: 20) {
                                FieldView(label: "Nationality", value: (document.nationality ?? "UNKNOWN").uppercased())
                                if let dob = document.birthDate {
                                    FieldView(label: "Date of Birth", value: dateFormatter.string(from: dob).uppercased())
                                }
                            }
                            
                            HStack(spacing: 20) {
                                if let iss = document.issueDate {
                                    FieldView(label: "Date of Issue", value: dateFormatter.string(from: iss).uppercased())
                                }
                                if let exp = document.expiryDate {
                                    FieldView(label: "Date of Expiry", value: dateFormatter.string(from: exp).uppercased())
                                }
                            }
                            
                            FieldView(label: "Place of Issue", value: document.placeOfIssue?.uppercased() ?? "OFFICIAL")
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 15)
                    }
                    
                    Spacer()
                    
                    // Machine Readable Zone (MRZ) - Simulated for Visa
                    VStack(spacing: 2) {
                        let countryCode = String(document.nationality?.prefix(3) ?? "VZA").uppercased()
                        let holderNameClean = document.holderName.replacingOccurrences(of: " ", with: "<<").uppercased()
                        Text("V<\(countryCode)\(holderNameClean)<<<<<<<<<<<<<<<<<<<<")
                        Text("\(document.detailValue.replacingOccurrences(of: " ", with: ""))<\(document.passportNumber?.replacingOccurrences(of: " ", with: "") ?? "00000000")<<<<<<<<<<<")
                    }
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.5))
                }
            }
            .overlay(
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 25)
                    .opacity(isOpen ? 1 : 0),
                alignment: .top
            )
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .frame(height: isOpen ? 480 : 240, alignment: .bottom)
    }
}

// MARK: - VISA FLIP CARD
struct VisaFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    @State private var isBookOpen = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isBackVisible {
                VisaInteriorView(document: document, isOpen: isBookOpen)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 490 : 240)
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                }
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.25)) {
                    isBookOpen = true
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isBookOpen = false
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    yRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                    isBackVisible = false
                }
            }
        }
    }
}

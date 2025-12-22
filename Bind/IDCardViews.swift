import SwiftUI

// MARK: - NEW: HELPER SHAPE FOR ROUNDED CORNERS
// A shape for a rectangle with only the top corners rounded.
fileprivate struct TopRoundedRectangle: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from bottom-left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Move to top-left, just before the curve
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        // Add top-left arc
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        // Line to top-right, just before the curve
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        // Add top-right arc
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: 270),
            endAngle: Angle(degrees: 360),
            clockwise: false
        )
        // Line to bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}


// MARK: - NEW: DRIVER'S LICENSE DETAIL VIEW (Back of Card)
struct DriversLicenseDetailView: View {
    let document: TravelDocument
    
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
        if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 240)
                .cornerRadius(20)
                .clipped()
        } else {
            ZStack {
                // Plastic Card Background
                Color(white: 0.95)
                
                // Decorative guilloche patterns
                Circle()
                    .fill(document.primaryColor.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: -80)
                
                VStack(spacing: 0) {
                    // Header Strip
                    HStack {
                        Image(systemName: document.iconName)
                            .foregroundColor(.white)
                        Text(document.title.uppercased())
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(1)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(document.primaryColor)
                    
                    // Main Content
                    HStack(alignment: .top, spacing: 10) {
                        // Photo & Signature
                        VStack(spacing: 8) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 100)
                                    .cornerRadius(4)
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("SIGNATURE")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 25)
                                .border(Color.gray.opacity(0.3), width: 1)
                        }
                        .padding([.leading, .top], 10)
                        
                        // Fields
                        VStack(alignment: .leading, spacing: 6) {
                            FieldView(label: "LICENSE NO.", value: document.detailValue)
                            FieldView(label: "SURNAME", value: names.surname)
                            FieldView(label: "GIVEN NAME", value: names.given)
                            
                            if let address = document.address, !address.isEmpty {
                                FieldView(label: "ADDRESS", value: address.uppercased())
                            }
                            
                            HStack(alignment: .top) {
                                if let dob = document.birthDate {
                                    FieldView(label: "DOB", value: dateFormatter.string(from: dob).uppercased())
                                }
                                if let exp = document.expiryDate {
                                    FieldView(label: "EXP", value: dateFormatter.string(from: exp).uppercased())
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Bottom Details Grid
                    HStack {
                        GridField(label: "CLASS", value: document.licenseClass)
                        GridField(label: "RESTR", value: document.restrictions)
                        GridField(label: "ENDOR", value: document.endorsements)
                        GridField(label: "EYES", value: document.eyeColor)
                        GridField(label: "HGT", value: document.height)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
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
    
    // Helper for bottom grid
    @ViewBuilder
    private func GridField(label: String, value: String?) -> some View {
        if let value = value, !value.isEmpty {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
        } else {
            EmptyView()
        }
    }
}

// MARK: - NEW: STUDENT ID DETAIL VIEW
struct StudentIdDetailView: View {
    let document: TravelDocument

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy" // Common expiry format
        return formatter
    }

    var body: some View {
        ZStack {
            // Card background
            Color.white

            VStack(spacing: 0) {
                // Header with university color
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.leading)

                    VStack(alignment: .leading) {
                        Text(document.title.uppercased()) // University Name
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("STUDENT IDENTIFICATION")
                            .font(.system(size: 8, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .frame(height: 50)
                .background(
                    TopRoundedRectangle(radius: 20)
                        .fill(document.primaryColor)
                )

                // Main content
                HStack(alignment: .top, spacing: 15) {
                    // Photo
                    VStack {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 90, height: 100)
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black.opacity(0.1), lineWidth: 0.5))
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50)
                                .foregroundColor(Color.gray.opacity(0.8))
                        }
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.holderName.uppercased())
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)

                        FieldView(label: "STUDENT NUMBER", value: document.detailValue)

                        if let exp = document.expiryDate {
                            FieldView(label: "EXPIRES", value: dateFormatter.string(from: exp))
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)

                Spacer()

                // Barcode simulation
                VStack(spacing: 3) {
                     HStack(spacing: 0) {
                         ForEach(0..<50) { _ in
                             Rectangle()
                                 .fill(Color.black)
                                 .frame(width: CGFloat.random(in: 1.0...2.5), height: 25)
                         }
                     }
                    .frame(height: 25)
                    .clipped()

                    Text(document.detailValue)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.black)
                        .tracking(2)
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
            }
        }
        .frame(height: 240)
        .cornerRadius(20)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}


// MARK: - GENERIC ID CARD DETAIL (Back of ID Card)
struct IDCardDetailView: View {
    let document: TravelDocument
    
    // Date Formatter Helper
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }
    
    // Name Splitter Helper
    var names: (surname: String, given: String) {
        let components = document.holderName.components(separatedBy: " ")
        if let last = components.last {
            let given = components.dropLast().joined(separator: " ")
            return (last.uppercased(), given.isEmpty ? last.uppercased() : given.uppercased())
        }
        return (document.holderName.uppercased(), "")
    }

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
                    Text(document.title.uppercased())
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
                        FieldView(label: "Surname", value: names.surname)
                        FieldView(label: "Given Names", value: names.given)
                        if let dob = document.birthDate {
                             FieldView(label: "Date of Birth", value: dateFormatter.string(from: dob).uppercased())
                        }
                        FieldView(label: "Document No.", value: document.detailValue)
                        if let exp = document.expiryDate {
                             FieldView(label: "Expires", value: dateFormatter.string(from: exp).uppercased())
                        }
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

// MARK: - ID CARD FLIP ANIMATION
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
                // Conditionally show the correct detail view based on type
                Group {
                    if document.type == .driversLicense {
                        DriversLicenseDetailView(document: document)
                    } else if document.type == .studentID {
                        StudentIdDetailView(document: document)
                    } else {
                        IDCardDetailView(document: document)
                    }
                }
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

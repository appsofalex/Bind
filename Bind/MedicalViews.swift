import SwiftUI

// MARK: - MEDICAL CARD DETAIL VIEW (Back of Card)
struct MedicalCardDetailView: View {
    let document: TravelDocument
    
    // Helper to extract Blood Type from "TYPE: A+" format
    var bloodType: String {
        if document.holderName.contains("TYPE:") {
            return document.holderName.replacingOccurrences(of: "TYPE: ", with: "")
        }
        return document.holderName
    }

    var body: some View {
        ZStack {
            // Plastic Card Background
            Color(white: 0.98)
            
            // Decorative background (Medical Cross pattern)
            GeometryReader { geo in
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    // Draw a large cross opacity overlay
                    let crossWidth: CGFloat = 80
                    let crossHeight: CGFloat = 200
                    
                    let centerX = width / 2
                    let centerY = height / 2
                    
                    // Vertical bar
                    path.addRect(CGRect(x: centerX - crossWidth/2, y: centerY - crossHeight/2, width: crossWidth, height: crossHeight))
                    // Horizontal bar
                    path.addRect(CGRect(x: centerX - crossHeight/2, y: centerY - crossWidth/2, width: crossHeight, height: crossWidth))
                }
                .fill(document.primaryColor.opacity(0.05))
            }
            
            VStack(spacing: 0) {
                // Header Strip
                HStack {
                    Image(systemName: "staroflife.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("MEDICAL CARD")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(document.primaryColor)
                
                // Main Content
                HStack(alignment: .top, spacing: 15) {
                    // Left Column: Blood Type (Prominent)
                    VStack(alignment: .center, spacing: 4) {
                        Text("BLOOD TYPE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        ZStack {
                            Circle()
                                .stroke(document.primaryColor, lineWidth: 2.5)
                                .frame(width: 60, height: 60)
                            
                            Text(bloodType)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(document.primaryColor)
                        }
                        
                        Image(systemName: "drop.fill")
                            .font(.subheadline)
                            .foregroundColor(document.primaryColor.opacity(0.6))
                    }
                    .frame(width: 80)
                    .padding(.top, 10)
                    
                    // Right Column: Emergency Contact
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMERGENCY CONTACT")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(document.primaryColor)
                            .padding(.bottom, -2)
                        
                        // Name
                        VStack(alignment: .leading, spacing: 0) {
                            Text("NAME")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.emergencyContactName?.isEmpty == false ? document.emergencyContactName! : "Not Set")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PHONE")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.emergencyPhoneNumber?.isEmpty == false ? document.emergencyPhoneNumber! : "Not Set")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 0) {
                            Text("EMAIL")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.emergencyContactEmail?.isEmpty == false ? document.emergencyContactEmail! : "Not Set")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Allergies Section
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLERGIES")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(document.primaryColor)
                    
                    Text(document.allergies?.isEmpty == false ? document.allergies! : "N/A")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(document.primaryColor.opacity(0.05))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 6)
                
                Spacer()
                
                // Bottom Strip
                HStack {
                    Text("In case of emergency, please contact the above immediately.")
                        .font(.system(size: 8, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(document.primaryColor.opacity(0.8))
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

// MARK: - VACCINATION CARD DETAIL VIEW
struct VaccinationCardDetailView: View {
    let document: TravelDocument
    
    // Extract info for cleaner display
    var vaccineName: String {
        document.subtitle.components(separatedBy: " - ").first ?? "VACCINE"
    }
    
    var doseInfo: String {
        document.dose ?? "Dose Unknown"
    }
    
    var body: some View {
        ZStack {
            // 1. Clinical White Background
            Color(white: 0.98)
            
            // 2. Subtle Watermark (Shield or Syringe)
            GeometryReader { geo in
                Image(systemName: "checkmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.6)
                    .foregroundColor(document.primaryColor.opacity(0.03))
                    .position(x: geo.size.width/2, y: geo.size.height/2)
            }
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Image(systemName: "syringe.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("IMMUNISATION RECORD")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                    Spacer()
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical,14)
                .background(document.primaryColor)
                
                // MAIN CONTENT
                VStack(alignment: .leading, spacing: 15) {
                    
                    // ROW 1: Patient & Vaccine (Prominent)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PATIENT NAME")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.holderName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Manufacturer Badge
                        if let manufacturer = document.manufacturer, !manufacturer.isEmpty {
                            Text(manufacturer)
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(document.primaryColor.opacity(0.1))
                                .foregroundColor(document.primaryColor)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 10)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    // ROW 2: Vaccine Details Grid - Using Grid for alignment
                    Grid(alignment: .topLeading, horizontalSpacing: 20, verticalSpacing: 12) {
                        GridRow {
                            // Vaccine (Left)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("VACCINE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(vaccineName)
                                    .font(.system(size: 14, weight: .heavy, design: .default))
                                    .foregroundColor(document.primaryColor)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            // Date (Right)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DATE ADMINISTERED")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        GridRow {
                            // Dose (Left)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DOSE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(doseInfo)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            
                            // Batch (Right)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("BATCH NO")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.detailValue)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    
                    // BOTTOM: Provider & Next Due
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ADMINISTERED BY")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.title) // Provider Name
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        if let nextDue = document.expiryDate {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("NEXT DUE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.red.opacity(0.7))
                                Text(nextDue.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                    }
                    .padding(.bottom, 22) // Increased padding to lift content up slightly
                }
                .padding(.horizontal, 20)
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

// MARK: - VACCINATION FLIP CARD
struct VaccinationFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            // BACK (Detail View)
            if isBackVisible {
                VaccinationCardDetailView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            // FRONT (Cover)
            else {
                DocumentCardView(document: document)
            }
        }
        .frame(height: 240)
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

struct MedicalFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            // BACK (Detail View)
            if isBackVisible {
                MedicalCardDetailView(document: document)
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

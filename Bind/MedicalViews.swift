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
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
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
                    Image(systemName: document.iconName)
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("MEDICAL CARD")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(document.primaryColor)
                
                // Main Content
                VStack(spacing: 8) {
                    HStack(alignment: .top, spacing: 15) {
                        // Left Column: Blood Type (Prominent)
                        VStack(alignment: .center, spacing: 4) {
                            Text("BLOOD TYPE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            ZStack {
                                Circle()
                                    .stroke(document.primaryColor, lineWidth: 2)
                                    .frame(width: 55, height: 55)
                                
                                Text(bloodType)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(document.primaryColor)
                            }
                            
                            Image(systemName: "drop.fill")
                                .font(.caption)
                                .foregroundColor(document.primaryColor.opacity(0.6))
                        }
                        .frame(width: 70)
                        .padding(.top, 8)
                        
                        // Right Column: Emergency Contact
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMERGENCY CONTACT")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(document.primaryColor)
                                .padding(.bottom, -2)
                            
                            // Name
                            VStack(alignment: .leading, spacing: 0) {
                                Text("NAME")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.emergencyContactName?.isEmpty == false ? document.emergencyContactName! : "Not Set")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                            
                            // Phone
                            VStack(alignment: .leading, spacing: 0) {
                                Text("PHONE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.emergencyPhoneNumber?.isEmpty == false ? document.emergencyPhoneNumber! : "Not Set")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 0) {
                                Text("EMAIL")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.emergencyContactEmail?.isEmpty == false ? document.emergencyContactEmail! : "Not Set")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Allergies Section
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALLERGIES")
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(document.primaryColor)
                        
                        Text(document.allergies?.isEmpty == false ? document.allergies! : "N/A")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(document.primaryColor.opacity(0.05))
                            .cornerRadius(8)
                            .lineLimit(2)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Bottom Strip
                HStack {
                    Text("In case of emergency, please contact the above immediately.")
                        .font(.system(size: 7.5, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
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
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
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
                // HEADER — flush to card top, top corners match card radius
                HStack {
                    Image(systemName: document.iconName)
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("IMMUNISATION RECORD")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                    .fill(document.primaryColor)
                )
                
                // MAIN CONTENT — more room to breathe
                VStack(alignment: .leading, spacing: 16) {
                    
                    // ROW 1: Patient & Vaccine (Prominent)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PATIENT NAME")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.holderName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Spacer()
                        
                        // Manufacturer Badge
                        if let manufacturer = document.manufacturer, !manufacturer.isEmpty {
                            Text(manufacturer)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(document.primaryColor.opacity(0.1))
                                .foregroundColor(document.primaryColor)
                                .cornerRadius(4)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 14)
                    
                    Divider()
                        .background(Color.gray.opacity(0.15))
                        .padding(.vertical, 2)
                    
                    // ROW 2: Vaccine Details Grid - Using Grid for alignment
                    Grid(alignment: .topLeading, horizontalSpacing: 20, verticalSpacing: 12) {
                        GridRow {
                            // Vaccine (Left)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("VACCINE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(vaccineName)
                                    .font(.system(size: 13, weight: .heavy, design: .default))
                                    .foregroundColor(document.primaryColor)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            // Date (Right)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DATE ADMINISTERED")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        GridRow {
                            // Dose (Left)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DOSE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(doseInfo)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            
                            // Batch (Right)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("BATCH NO")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.detailValue)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let nextDue = document.expiryDate {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("NEXT DUE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.red.opacity(0.7))
                                Text(nextDue.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
            }
        }
    }
}

// MARK: - PRESCRIPTION CARD DETAIL VIEW
struct PrescriptionCardDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
            ZStack {
            // Pharmacy White Background
            Color(white: 0.98)
            
            // Subtle watermark
            GeometryReader { geo in
                Image(systemName: "pills.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.5)
                    .foregroundColor(document.primaryColor.opacity(0.04))
                    .position(x: geo.size.width/2, y: geo.size.height/2)
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: document.iconName)
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("PRESCRIPTION RECORD")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                    Spacer()
                    Text("RX")
                        .font(.system(size: 14, weight: .black, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(document.primaryColor)
                
                VStack(alignment: .leading, spacing: 10) {
                    // ROW 1: Medication & Patient
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MEDICATION")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.title)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(document.primaryColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("PATIENT")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.holderName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.15))
                    
                    // ROW 2: Instructions Grid
                    Grid(alignment: .topLeading, horizontalSpacing: 25, verticalSpacing: 8) {
                        GridRow {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DOSAGE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.subtitle)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("FREQUENCY")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.frequency ?? "N/A")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        
                        GridRow {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("ROUTE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.route ?? "N/A")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("REFILLS")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.refills ?? "0")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(document.refills == "0" ? .red.opacity(0.7) : .black)
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.1))
                    
                    // ROW 3: Provider Info
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text("DOCTOR:")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.doctorName?.isEmpty == false ? document.doctorName! : "N/A")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 4) {
                                Text("PHARMACY:")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.pharmacyName?.isEmpty == false ? document.pharmacyName! : "N/A")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("RX NO.")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.detailValue)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer(minLength: 5)
                    
                    // Footer Dates
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DATE PRESCRIBED")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.gray)
                            Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        if let expiry = document.expiryDate {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("EXPIRATION DATE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(expiry.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                    }
                    .padding(.bottom, 15)
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
    }
}

// MARK: - PRESCRIPTION FLIP CARD
struct PrescriptionFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                PrescriptionCardDetailView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
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

// MARK: - INSURANCE FLIP CARD (back shows full image when photo added)
struct InsuranceFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                InsuranceCardBackView(document: document)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                DocumentCardView(document: document)
            }
        }
        .frame(height: 240)
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

struct InsuranceCardBackView: View {
    let document: TravelDocument

    // Date + formatting helpers
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }

    private var coverageStart: String {
        if let start = document.issueDate {
            return dateFormatter.string(from: start)
        }
        return "Not set"
    }

    private var coverageEnd: String {
        if let end = document.expiryDate {
            return dateFormatter.string(from: end)
        }
        return "Not set"
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
            Spacer(minLength: 10)
            Text(value.isEmpty ? "Not set" : value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
    
    var body: some View {
        ZStack {
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ZStack {
                    // Detailed insurance layout (matches Add Health Insurance fields)
                    Color(white: 0.98)

                    VStack(spacing: 0) {
                        // Header – provider + plan (condensed)
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: document.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(document.title.isEmpty ? "INSURANCE PROVIDER" : document.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                if !document.subtitle.isEmpty {
                                    Text(document.subtitle.displayCapitalized)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.9))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(document.primaryColor)

                        // Main content
                        VStack(alignment: .leading, spacing: 0) {
                            infoRow(label: "Policy holder", value: document.holderName)
                            infoRow(label: "Policy number", value: document.detailValue)
                            infoRow(label: "Group number", value: document.groupNumber ?? "")
                            infoRow(label: "Coverage start", value: coverageStart)
                            infoRow(label: "Coverage end", value: coverageEnd)
                            infoRow(label: "Emergency contact", value: document.emergencyPhoneNumber ?? "")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        Spacer(minLength: 0)

                        // Footer (condensed)
                        HStack {
                            Text("Present this card to your provider when receiving care.")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(document.primaryColor.opacity(0.85))
                    }
                }
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

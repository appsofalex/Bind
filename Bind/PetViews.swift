import SwiftUI

// MARK: - PET INSURANCE DETAIL VIEW (Back of Card)
struct PetInsuranceDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            // Plastic Card Background
            Color(white: 0.98)
            
            // Decorative background (Medical Cross pattern)
            GeometryReader { geo in
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    let crossWidth: CGFloat = 80
                    let crossHeight: CGFloat = 200
                    let centerX = width / 2
                    let centerY = height / 2
                    path.addRect(CGRect(x: centerX - crossWidth/2, y: centerY - crossHeight/2, width: crossWidth, height: crossHeight))
                    path.addRect(CGRect(x: centerX - crossHeight/2, y: centerY - crossWidth/2, width: crossHeight, height: crossWidth))
                }
                .fill(document.primaryColor.opacity(0.05))
            }
            
            VStack(spacing: 0) {
                // Header Strip
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("PET INSURANCE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(document.primaryColor)
                
                // Main Content
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 20) {
                        // Pet Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PET NAME")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.petName ?? "Unknown")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("SPECIES / BREED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                            Text("\(document.petSpecies ?? "Other") / \(document.petBreed ?? "Unknown")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Policy Info
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("POLICY NUMBER")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.detailValue)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(document.primaryColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Divider().padding(.horizontal)
                    
                    // Validity Dates
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("START DATE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("EXPIRY DATE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Provider Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("INSURANCE PROVIDER")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(document.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Bottom Strip
                HStack {
                    Text("This card confirms active pet insurance coverage.")
                        .font(.system(size: 8, weight: .medium))
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

// MARK: - PET VACCINATION DETAIL VIEW
struct PetVaccinationDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            Color(white: 0.98)
            
            GeometryReader { geo in
                Image(systemName: "syringe.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.5)
                    .foregroundColor(document.primaryColor.opacity(0.03))
                    .position(x: geo.size.width/2, y: geo.size.height/2)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "syringe.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("PET VACCINATION")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(document.primaryColor)
                
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PET NAME")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.petName ?? "Unknown")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("VACCINE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                            Text(document.subtitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(document.primaryColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("BATCH NUMBER")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.detailValue)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Divider().padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DATE ADMINISTERED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NEXT DUE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(document.expiryDate ?? Date() < Date() ? .red : .primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VETERINARY CLINIC")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(document.title)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                HStack {
                    Text("Official veterinary record of vaccination.")
                        .font(.system(size: 8, weight: .medium))
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

// MARK: - PET PASSPORT / ID DETAIL VIEW
struct PetPassportDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        ZStack {
            Color(white: 0.98)
            
            GeometryReader { geo in
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.6)
                    .foregroundColor(document.primaryColor.opacity(0.03))
                    .position(x: geo.size.width/2, y: geo.size.height/2)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text(document.type == .petPassport ? "PET PASSPORT" : "PET IDENTIFICATION")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Text(document.title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(document.primaryColor)
                
                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 15) {
                        // Pet Photo Placeholder or Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 80, height: 100)
                            
                            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(document.primaryColor.opacity(0.2))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("PET NAME")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.petName ?? "Unknown")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("SPECIES / BREED")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("\(document.petSpecies ?? "Other") / \(document.petBreed ?? "Unknown")")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("MICROCHIP / ID")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.petMicrochipNumber ?? "None")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(document.primaryColor)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Divider().padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ISSUE DATE")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        Spacer()
                        if let dob = document.birthDate {
                            VStack(alignment: .center, spacing: 2) {
                                Text("DATE OF BIRTH")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(dob.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            Spacer()
                        }
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("EXPIRY DATE")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(document.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                HStack {
                    Text("Official pet identification and travel document.")
                        .font(.system(size: 8, weight: .medium))
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

// MARK: - PET ANIMATED CARD (FLIP LOGIC)
struct PetAnimatedCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK SIDE
                Group {
                    switch document.type {
                    case .petInsurance:
                        PetInsuranceDetailView(document: document)
                    case .petVaccineRecord:
                        PetVaccinationDetailView(document: document)
                    case .petPassport, .petID:
                        PetPassportDetailView(document: document)
                    default:
                        DocumentCardView(document: document)
                    }
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT SIDE
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

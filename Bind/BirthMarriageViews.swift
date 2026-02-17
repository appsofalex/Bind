import SwiftUI

// A4 portrait aspect ratio (210 × 297 mm)
private let a4PortraitRatio: CGFloat = 210.0 / 297.0   // width / height

// MARK: - BIRTH CERTIFICATE DETAIL VIEW (A4 portrait industry standard)
struct BirthCertificateDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        Group {
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(RoundedRectangle(cornerRadius: 20))
            } else {
            ZStack {
            // Antique Paper Background
                    Color(red: 0.98, green: 0.97, blue: 0.92)
                    
                    // Decorative Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(document.primaryColor.opacity(0.2), lineWidth: 8)
                        .padding(5)
                    
                    // Watermark Seal
                    GeometryReader { geo in
                        Image(systemName: document.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.4)
                            .foregroundColor(document.primaryColor.opacity(0.05))
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.7)
                    }
                    
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 2) {
                            Text("CERTIFICATE OF BIRTH")
                                .font(.system(size: 14, weight: .black, design: .serif))
                                .foregroundColor(document.primaryColor)
                                .tracking(1.5)
                            
                            Rectangle()
                                .fill(document.primaryColor.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 15)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 1) {
                                Text("FULL NAME")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(document.holderName.uppercased())
                                    .font(.system(size: 16, weight: .heavy, design: .serif))
                                    .foregroundColor(.black)
                            }
                            
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("DATE OF BIRTH")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.birthDate?.formatted(date: .abbreviated, time: .omitted).uppercased() ?? "N/A")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("GENDER")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.gender?.uppercased() ?? "N/A")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("PLACE OF BIRTH")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.placeOfBirth?.uppercased() ?? "N/A")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                }
                            }
                            
                            Divider().background(document.primaryColor.opacity(0.1))
                            
                            HStack(spacing: 30) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("FATHER'S NAME")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.fatherName?.uppercased() ?? "N/A")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("MOTHER'S NAME")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.motherName?.uppercased() ?? "N/A")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Spacer(minLength: 5)
                            
                            // Footer Details
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("REGISTRATION DATE:")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.gray)
                                        Text(document.issueDate?.formatted(date: .numeric, time: .omitted) ?? "N/A")
                                            .font(.system(size: 7, weight: .bold))
                                    }
                                    HStack {
                                        Text("REGISTRATION DISTRICT:")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.gray)
                                        Text(document.registrationDistrict?.uppercased() ?? "N/A")
                                            .font(.system(size: 7, weight: .bold))
                                    }
                                    HStack {
                                        Text("ISSUING AUTHORITY:")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.gray)
                                        Text(document.issuingAuthority?.uppercased() ?? "N/A")
                                            .font(.system(size: 7, weight: .bold))
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("CERTIFICATE NO.")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.detailValue)
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundColor(document.primaryColor)
                                }
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(a4PortraitRatio, contentMode: .fit)
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - MARRIAGE CERTIFICATE DETAIL VIEW (A4 portrait, same as birth certificate)
struct MarriageCertificateDetailView: View {
    let document: TravelDocument
    
    var body: some View {
        Group {
            if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(RoundedRectangle(cornerRadius: 20))
            } else {
                ZStack {
                    // Elegant Cream Background
                    Color(red: 0.99, green: 0.98, blue: 0.95)
                    
                    // Floral or Scroll Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(document.primaryColor.opacity(0.15), lineWidth: 4)
                        .padding(10)
                    
                    // Watermark Rings
                    GeometryReader { geo in
                        Image(systemName: "infinity")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.3)
                            .foregroundColor(document.primaryColor.opacity(0.04))
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    }
                    
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 4) {
                            Text("CERTIFICATE OF MARRIAGE")
                                .font(.system(size: 13, weight: .black, design: .serif))
                                .foregroundColor(document.primaryColor)
                                .tracking(2)
                            
                            HStack {
                                Rectangle().fill(document.primaryColor.opacity(0.2)).frame(height: 1)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(document.primaryColor.opacity(0.4))
                                Rectangle().fill(document.primaryColor.opacity(0.2)).frame(height: 1)
                            }
                            .padding(.horizontal, 50)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            // Spouses
                            VStack(spacing: 4) {
                                Text(document.holderName.uppercased())
                                    .font(.system(size: 14, weight: .heavy, design: .serif))
                                Text("&")
                                    .font(.system(size: 10, weight: .light, design: .serif))
                                    .italic()
                                Text(document.spouseName?.uppercased() ?? "SPOUSE NAME")
                                    .font(.system(size: 14, weight: .heavy, design: .serif))
                            }
                            .foregroundColor(.black)
                            
                            Divider().background(document.primaryColor.opacity(0.1)).padding(.horizontal, 30)
                            
                            HStack(alignment: .top, spacing: 30) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DATE OF MARRIAGE")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.marriageDate?.formatted(date: .long, time: .omitted).uppercased() ?? "N/A")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PLACE OF MARRIAGE")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.marriagePlace?.uppercased() ?? "N/A")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 40) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("OFFICIANT")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.officiantName?.uppercased() ?? "N/A")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("WITNESSES")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.witnesses?.uppercased() ?? "N/A")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            // Footer
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ISSUING AUTHORITY")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.issuingAuthority?.uppercased() ?? "N/A")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("LICENSE NO.")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(document.detailValue)
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                        .foregroundColor(document.primaryColor)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(a4PortraitRatio, contentMode: .fit)
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - BIRTH CERTIFICATE FLIP CARD (A4 portrait when expanded)
struct BirthCertificateFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        GeometryReader { geo in
            let backHeight = geo.size.width * (297.0 / 210.0)
            ZStack {
                if isBackVisible {
                    BirthCertificateDetailView(document: document)
                        .frame(width: geo.size.width, height: backHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    DocumentCardView(document: document)
                }
            }
            .frame(width: geo.size.width, height: isBackVisible ? backHeight : 240)
        }
        .frame(height: isBackVisible ? (UIScreen.main.bounds.width - 40) * (297.0 / 210.0) : 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

// MARK: - MARRIAGE CERTIFICATE FLIP CARD (A4 portrait when expanded, same as birth certificate)
struct MarriageCertificateFlipCard: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    var body: some View {
        GeometryReader { geo in
            let backHeight = geo.size.width * (297.0 / 210.0)
            ZStack {
                if isBackVisible {
                    MarriageCertificateDetailView(document: document)
                        .frame(width: geo.size.width, height: backHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    DocumentCardView(document: document)
                }
            }
            .frame(width: geo.size.width, height: isBackVisible ? backHeight : 240)
        }
        .frame(height: isBackVisible ? (UIScreen.main.bounds.width - 40) * (297.0 / 210.0) : 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

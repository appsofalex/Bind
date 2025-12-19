import SwiftUI

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

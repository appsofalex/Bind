import SwiftUI

struct PassportDetailView: View {
    // We pass the document data in
    let document: TravelDocument
    // We bind to the parent view to close it
    @Binding var isPresented: Bool
    
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    
    // Animation State
    @State private var unfoldState: Double = -90 // Starts folded backward
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark Backdrop (The "Table")
            Color.black.opacity(0.9).ignoresSafeArea()
                .onTapGesture {
                    closeView()
                }
            
            // THE PASSPORT BOOKLET
            VStack(spacing: 0) {
                
                // --- TOP PAGE (Country & Crest) ---
                ZStack {
                    // "Paper" Texture
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                        )
                    
                    // Watermark
                    Image(systemName: document.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                        .foregroundColor(.white.opacity(0.03))
                    
                    VStack(spacing: 15) {
                        Text(document.title.uppercased())
                            .font(.system(size: 24, weight: .black, design: .serif))
                            .tracking(2)
                            .foregroundColor(document.secondaryColor)
                        
                        Image(systemName: document.iconName)
                            .font(.system(size: 60))
                            .foregroundColor(document.secondaryColor.opacity(0.8))
                        
                        Text("PASSPORT")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .tracking(5)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(height: 300)
                .clipped()
                
                // --- THE SPINE (Crease) ---
                Rectangle()
                    .fill(LinearGradient(colors: [.black.opacity(0.8), .black.opacity(0.2), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 12)
                    .zIndex(10)
                
                // --- BOTTOM PAGE (Data & Photo) ---
                ZStack {
                    if let imageData = document.documentImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 380)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        // "Paper" Texture
                        Rectangle()
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.92)) // Off-white paper for contrast
                        
                        // Fine security pattern overlay
                        Image(systemName: "shield.checkerboard")
                            .resizable()
                            .opacity(0.05)
                            .foregroundColor(.blue)
                            .scaleEffect(1.5)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            
                            // Header: Type / Code / No
                            HStack {
                                dataField(label: "Type", value: "P")
                                Spacer()
                                dataField(label: "Code", value: "GBR")
                                Spacer()
                                dataField(label: "Passport No", value: document.detailValue)
                            }
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 20) {
                                // PHOTO AREA
                                VStack {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 130)
                                        
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    }
                                    .cornerRadius(5)
                                }
                                
                                // DETAILS AREA
                                VStack(alignment: .leading, spacing: 12) {
                                    dataField(label: "Surname", value: "HARTDEGEN")
                                    dataField(label: "Given Names", value: "ALEXANDER")
                                    dataField(label: "Nationality", value: "BRITISH CITIZEN")
                                    
                                    HStack {
                                        dataField(label: "Date of Birth", value: "12 JAN 1990")
                                        Spacer()
                                        dataField(label: "Sex", value: "M")
                                    }
                                    
                                    dataField(label: "Date of Expiry", value: "12 JAN 2030")
                                }
                            }
                            
                            Spacer()
                            
                            // MRZ CODE (The machine readable bottom part)
                            VStack(spacing: 2) {
                                Text("P<GBRHARTDEGEN<<ALEXANDER<<<<<<<<<<<<<<<<<<<")
                                Text("9832019928GBR9001129M3001126<<<<<<<<<<<<<<02")
                            }
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                        }
                        .padding(25)
                    }
                }
                .frame(height: 380)
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 20)
            
            // --- ANIMATION MODIFIERS ---
            // This rotation creates the "Opening book" effect
            .rotation3DEffect(
                .degrees(unfoldState),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top, // Pivot from the top
                anchorZ: 0,
                perspective: 0.3
            )
            .opacity(contentOpacity)
        }
        .onAppear {
            animateOpening()
        }
    }
    
    // Helper to make data fields look official
    func dataField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .serif)) // Serif looks like printed type
                .foregroundColor(.black)
        }
    }
    
    func animateOpening() {
        // Simple "Thud" opening animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            unfoldState = 0
            contentOpacity = 1
        }
        
        // Haptic feedback for "opening"
        if isHapticsEnabled {
            HapticManager.shared.triggerImpact(style: .heavy)
        }
    }
    
    func closeView() {
            // 👇 Updated to use cubic-bezier (0.25, 0.1, 0.25, 1)
            withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.2)) {
                contentOpacity = 0
                unfoldState = -45
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
        }
    }
}

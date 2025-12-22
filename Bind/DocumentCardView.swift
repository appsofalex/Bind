import SwiftUI

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
            
            // High-Resolution Texture Icon
            Image(systemName: document.iconName)
                // 1. Render the symbol as a large, vector-based font character for sharpness.
                .font(.system(size: 300, weight: .thin))
                // 2. Force the view into a consistent 300x300 frame to ensure
                //    its center is always in the same place for the .position() modifier.
                .frame(width: 300, height: 300)
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
                    
                    Text(document.subtitle.uppercased())
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
                    
                    if document.type == .insurance, let phone = document.emergencyPhoneNumber, !phone.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "phone.fill")
                                .font(.callout)
                            Text(phone)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    } else {
                        Image(systemName: "qrcode")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    }
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

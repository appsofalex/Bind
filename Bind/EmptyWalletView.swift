import SwiftUI

// MARK: - EMPTY WALLET VIEW (Extracted for reliable animation reset)
struct EmptyWalletView: View {
    @State private var animateArrow = false
    
    var body: some View {
        ZStack {
            // Text Content
            VStack(spacing: 15) {
                Spacer()
                
                Image(systemName: "wallet.pass")
                    .font(.system(size: 70))
                    .foregroundColor(.primary.opacity(0.2))
                    .padding(.bottom, 10)
                
                Text("No Cards Yet")
                    .font(.system(size: 24, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                
                Text("Add your first document or booking by clicking the '+' button.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                
                Spacer()
                    .frame(height: 30)
                
                Spacer()
            }
            .zIndex(0)
            
            // Animated Pointing Arrow
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.right") // Using the curved arrow
                        .font(.system(size: 35, weight: .light))
                        .foregroundColor(.primary.opacity(0.6))
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
                        
                        .timingCurve(0.25, 0.1, 0.25, 1, duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateArrow = true
            }
        }
    }
}

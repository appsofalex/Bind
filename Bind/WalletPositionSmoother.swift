import SwiftUI

// MARK: - HELPER VIEW FOR SMOOTH WRAPPING (extracted to reduce ContentView type-check complexity)
struct WalletPositionSmoother<Content: View>: View {
    var target: CGFloat
    var totalHeight: CGFloat
    @ViewBuilder var content: (CGFloat) -> Content
    
    @State private var currentVisualPosition: CGFloat?
    
    var body: some View {
        content(currentVisualPosition ?? target)
            .onAppear {
                currentVisualPosition = target
            }
            .onChange(of: target) { newValue in
                guard let oldVal = currentVisualPosition else {
                    currentVisualPosition = newValue
                    return
                }
                
                let delta = newValue - oldVal
                
                // Detect Wrap: If change is larger than half the loop
                if abs(delta) > (totalHeight * 0.5) {
                    // Animate the snap (wrap around)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        currentVisualPosition = newValue
                    }
                } else {
                    // Instant update for drag/scroll
                    currentVisualPosition = newValue
                }
            }
    }
}

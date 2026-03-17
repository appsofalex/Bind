import SwiftUI

// PRO BADGE VIEW
struct ProBadgeView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    @State private var gradientProgress: CGFloat = 0
    @State private var glowScale: CGFloat = 0.0
    @State private var isAnimating = false
    
    // Hatch/Pop animation states
    @State private var cardScale: CGFloat = 0.0
    @State private var cardOpacity: Double = 0.0
    @State private var cardRotation: Double = 0.0
    @State private var cardYOffset: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // "Hatching" Card
            if isAnimating {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.8))
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .rotationEffect(.degrees(cardRotation))
                    .offset(y: cardYOffset)
            }
            
            // The PRO Badge
            if isAnimating || subscriptionManager.isPro {
                Text("PRO")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(gradientProgress)
                            
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                .opacity(gradientProgress)
                        }
                    )
                    .shadow(color: Color.purple.opacity(0.5 * gradientProgress), radius: 8, x: 0, y: 0)
                    .scaleEffect(glowScale)
            }
        }
        .onAppear {
            if subscriptionManager.showUpgradeAnimation {
                runUpgradeAnimation()
            } else if subscriptionManager.isPro {
                gradientProgress = 1.0
                glowScale = 1.0
            }
        }
        .onChange(of: subscriptionManager.showUpgradeAnimation) { newValue in
            if newValue {
                runUpgradeAnimation()
            }
        }
    }
    
    private func runUpgradeAnimation() {
        isAnimating = true
        gradientProgress = 0
        glowScale = 0
        cardScale = 0
        cardOpacity = 0
        cardRotation = 0
        cardYOffset = 0
        
        let initialDelay = 0.6 // 600ms delay
        
        // 1. Card pops in
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cardScale = 1.2
                cardOpacity = 1.0
            }
            
            // 2. Card "hatches" / reveals PRO
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Haptic for the "pop"
                if isHapticsEnabled {
                    HapticManager.shared.triggerImpact(style: .heavy)
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cardScale = 1.5
                    cardRotation = 15
                    cardYOffset = -20
                    cardOpacity = 0
                    
                    glowScale = 1.1
                    gradientProgress = 1.0
                }
                
                // 3. Settle into place
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        glowScale = 1.0
                    }
                    
                    // Final cleanup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        subscriptionManager.showUpgradeAnimation = false
                        isAnimating = false
                    }
                }
            }
        }
    }
}

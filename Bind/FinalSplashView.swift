import SwiftUI

struct FinalSplashView: View {
    // Visibility states
    @State private var showSimplyBound = false
    @State private var showSecurelyYours = false
    
    // Animation states
    @State private var sloganScale: CGFloat = 1.0
    @State private var sloganOpacity: Double = 1.0
    @State private var screenOpacity: Double = 1.0
    
    var onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
                
                // Central Slogan
                VStack(spacing: 12) {
                    Text("Simply Bound")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showSimplyBound ? 1 : 0)
                        .offset(y: showSimplyBound ? 0 : 20)
                    
                    Text("Securely Yours")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showSecurelyYours ? 1 : 0)
                        .offset(y: showSecurelyYours ? 0 : 20)
                }
                .scaleEffect(sloganScale)
                .opacity(sloganOpacity)
                // Use a standard spring for the entry of each line
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showSimplyBound)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showSecurelyYours)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                runSequence()
            }
        }
    }
    
    private func runSequence() {
        // 1. "Simply Bound" appears centrally
        withAnimation(.easeOut(duration: 0.8)) {
            showSimplyBound = true
        }
        
        // 2. "Securely Yours" follows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.8)) {
                showSecurelyYours = true
            }
        }
        
        // 3. Final Transition into the App
        // Brief pause to let the user read the full slogan
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // We ONLY fade the slogans, not the background.
            // This prevents the onboarding screen behind from being revealed.
            withAnimation(.easeInOut(duration: 0.8)) {
                sloganScale = 1.1
                sloganOpacity = 0
            }
            
            // Hand over to the main app while this view is still covering the screen with its background
            // We wait for the slogan fade (0.8s) to complete before triggering the hand-off.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete()
            }
        }
    }
}

import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    var onSuccess: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPulsing = false
    @State private var isVisuallyUnlocked = false
    @State private var isAnimatingUnlock = false
    
    // Matches the app background color used in Onboarding
    var appBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        } else {
            return Color(red: 0.96, green: 0.96, blue: 0.97)
        }
    }
    
    var body: some View {
        ZStack {
            appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                ZStack {
                    // Closed lock
                    Image(systemName: "lock.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                        .opacity(isVisuallyUnlocked ? 0 : 1)
                        .scaleEffect(isPulsing ? 1.04 : 0.98)
                        .rotationEffect(.degrees(isAnimatingUnlock ? -8 : 0))
                        .offset(y: isAnimatingUnlock ? 10 : 0)
                        .animation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.1),
                            value: isAnimatingUnlock
                        )
                    
                    // Open lock
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                        .opacity(isVisuallyUnlocked ? 1 : 0)
                        .scaleEffect(isVisuallyUnlocked ? 1.05 : 0.9)
                        .offset(y: isVisuallyUnlocked ? 0 : -14)
                        .rotationEffect(.degrees(isVisuallyUnlocked ? 0 : 10))
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8, blendDuration: 0.15),
                            value: isVisuallyUnlocked
                        )
                }
                .padding(.bottom, 20)
                
                VStack(spacing: 16) {
                    Text("All your Bind cards are secure")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Unlock using Face ID")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    authenticate()
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Unlock")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .clipShape(Capsule())
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isVisuallyUnlocked = false
            isAnimatingUnlock = false
            
            // Start subtle breathing animation on the closed lock
            DispatchQueue.main.async {
                isPulsing = true
            }
            
            authenticate()
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // policy: .deviceOwnerAuthentication allows Biometrics (Face ID/Touch ID) 
        // AND falls back to device passcode if biometrics fail or are unavailable.
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock to access your secure documents"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Animate the lock visually unlocking before transitioning away
                        isAnimatingUnlock = true
                        isPulsing = false
                        
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8, blendDuration: 0.15)) {
                            isVisuallyUnlocked = true
                        }
                        
                        // Give the unlock animation a moment to play before dismissing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            withAnimation {
                                onSuccess()
                            }
                        }
                    }
                }
            }
        }
    }
}

import SwiftUI
import LocalAuthentication

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showFooter = false
    let totalPages = 4 // Welcome, Centralize, FaceID, Final
    
    // Exact background color from main app
    let appBackgroundColor = Color(red: 0.11, green: 0.11, blue: 0.12)
    
    var body: some View {
        ZStack {
            // Background
            appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content Area
                TabView(selection: $currentPage) {
                    WelcomePageView(showText: $showFooter)
                        .tag(0)
                    
                    CentralizePageView(isSelected: currentPage == 1)
                        .tag(1)
                    
                    FaceIDPageView(isSelected: currentPage == 2)
                        .tag(2)
                    
                    FinalPageView(isSelected: currentPage == 3)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Footer Area
                VStack(spacing: 24) {
                    // Custom Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.2))
                                .frame(width: currentPage == index ? 32 : 8, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action Button
                    Button(action: {
                        if currentPage == 2 {
                            // FaceID Logic
                            authenticate()
                        } else {
                            withAnimation {
                                if currentPage < totalPages - 1 {
                                    currentPage += 1
                                } else {
                                    // Final step
                                    hasCompletedOnboarding = true
                                }
                            }
                        }
                    }) {
                        Text(buttonText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.white.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(currentPage == 0 ? (showFooter ? 1 : 0) : 1)
                .offset(y: currentPage == 0 ? (showFooter ? 0 : 20) : 0)
                .padding(.bottom, 50)
            }
        }
    }
    
    var buttonText: String {
        switch currentPage {
        case 0: return "Get Started"
        case 2: return "Enable Face ID"
        case 3: return "Enter Bind"
        default: return "Continue"
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Secure your documents with FaceID"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Success - Move to next screen
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Failed or Cancelled - Move to next screen anyway for now
                         withAnimation {
                            currentPage += 1
                        }
                    }
                }
            }
        } else {
            // Biometrics not available, skip
            withAnimation {
                currentPage += 1
            }
        }
    }
}

// MARK: - Page 1: Welcome / Introduction
struct WelcomePageView: View {
    @Binding var showText: Bool
    @State private var moveOrbitsUp = false
    @State private var orbitOpacity = 0.0
    @State private var orbitScale = 0.6 // Start smaller for dramatic entry
    @State private var orbitBlur = 20.0 // Start very blurred
    @State private var innerRotationOffset: Double = -30 // Extra rotation for entry
    
    var body: some View {
        GeometryReader { geo in
            // Calculate the exact offset needed to reach the true center of the device screen
            let globalFrame = geo.frame(in: .global)
            let screenHeight = UIScreen.main.bounds.height
            let trueCenterOffset = (screenHeight / 2) - globalFrame.midY
            
            ZStack {
                // 1. Standard Layout for Text Alignment (Matches other pages exactly)
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Invisible placeholder for Orbit slot to maintain layout consistency
                    Color.clear.frame(height: 350)
                    
                    Spacer().frame(height: 40)
                    
                    // Text Content
                    VStack(spacing: 16) {
                        Text("Welcome to Bind")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("The new home for life’s most important documents. Secure, organised, and always with you.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                    }
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)
                    
                    Spacer()
                        .frame(height: 50)
                }
                
                // 2. Orbit Animation
                // Starts at trueCenterOffset (screen middle) and shifts to its final position
                OrbitView(extraRotation: innerRotationOffset)
                    .scaleEffect(orbitScale)
                    .blur(radius: orbitBlur)
                    .opacity(orbitOpacity)
                    .offset(y: moveOrbitsUp ? -geo.size.height * 0.14 : trueCenterOffset)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                // Dramatic entry sequence: slow fade, scale, and de-blur
                withAnimation(.easeOut(duration: 2.5)) {
                    orbitOpacity = 1.0
                    orbitScale = 1.05
                    orbitBlur = 0
                    innerRotationOffset = 0
                }
                
                // Shift up and show text after the suspenseful intro
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.spring(response: 1.2, dampingFraction: 0.85)) {
                        moveOrbitsUp = true
                        showText = true
                    }
                }
            }
        }
    }
}

struct OrbitView: View {
    var extraRotation: Double = 0
    @State private var rotation: Double = 0
    @State private var poppingIndex: Int? = nil
    
    // Icons for the inner orbit (6 icons)
    let innerIcons = ["airplane", "creditcard.fill", "ticket.fill", "person.text.rectangle.fill", "car.fill", "doc.text.fill"]
    
    var body: some View {
        ZStack {
            // Background Orbit Paths
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.white.opacity(0.01), .white.opacity(0.1), .white.opacity(0.01)]),
                        center: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: 220, height: 220)

            // Central Card Icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 85, height: 85)
                    .shadow(color: .white.opacity(0.15), radius: 25)
                
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.black)
                    .font(.system(size: 38, weight: .medium))
            }
            
            // Inner Orbit (6 icons rotating clockwise)
            ForEach(0..<innerIcons.count, id: \.self) { index in
                let initialAngle = Double(index) * (360.0 / Double(innerIcons.count))
                let currentRotation = initialAngle + rotation + extraRotation
                
                OrbitIcon(
                    iconName: innerIcons[index],
                    counterRotation: -currentRotation,
                    isPopping: poppingIndex == index
                )
                .offset(x: 110)
                .rotationEffect(.degrees(currentRotation))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 35).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            startPoppingCycle()
        }
    }
    
    private func startPoppingCycle() {
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                poppingIndex = currentIndex
                currentIndex = (currentIndex + 1) % innerIcons.count
            }
        }
    }
}

struct OrbitIcon: View {
    let iconName: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 22
    var counterRotation: Double
    var isPopping: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.15), radius: 8)
            
            Image(systemName: iconName)
                .foregroundColor(.black)
                .font(.system(size: iconSize, weight: .medium))
        }
        .scaleEffect(isPopping ? 1.35 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: isPopping)
        .rotationEffect(.degrees(counterRotation))
    }
}

// MARK: - Page 2: Centralization / Ecosystem
struct CentralizePageView: View {
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Floating Cards Animation
            ZStack {
                // Background Card 1
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.2))
                    .frame(width: 200, height: 140)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -40, y: -20)
                    .opacity(isSelected ? 0.6 : 0)
                    .scaleEffect(isSelected ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isSelected)
                
                // Background Card 2
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.3))
                    .frame(width: 200, height: 140)
                    .rotationEffect(.degrees(12))
                    .offset(x: 40, y: -10)
                    .opacity(isSelected ? 0.8 : 0)
                    .scaleEffect(isSelected ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isSelected)
                
                // Main Card
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.25), Color.black], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 220, height: 150)
                    .overlay(
                        // REMOVED TEXT, ENLARGED ICON
                        Image(systemName: "folder.fill")
                            .font(.system(size: 60)) // Larger icon
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .offset(y: isSelected ? 0 : 40)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: isSelected)
            }
            .frame(height: 350)
            .offset(y: -30)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Stop the scramble")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Passports, insurance, tickets, and IDs - centralised in one ecosystem. No more digging through photos or files.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            .offset(y: 0)
            
            Spacer()
                .frame(height: 50)
        }
    }
}

// MARK: - Page 3: Face ID
struct FaceIDPageView: View {
    let isSelected: Bool
    @State private var breathe = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // FaceID Icon Animation
            ZStack {
                // Native FaceID Icon (White, with smooth breathing pulse)
                Image(systemName: "faceid")
                    .font(.system(size: 110, weight: .regular))
                    .foregroundColor(.white)
                    // Base entry animation (scale from 0.6 to 1.0)
                    .scaleEffect(isSelected ? (breathe ? 1.06 : 1.0) : 0.6)
                    .opacity(isSelected ? 1.0 : 0.0)
                    // Entry spring animation
                    .animation(.spring(response: 0.8, dampingFraction: 0.45).delay(0.1), value: isSelected)
                    // Breathing pulse animation (smoothly loops)
                    .animation(isSelected ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: breathe)
            }
            .frame(height: 350)
            .offset(y: -30)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Secure with Face ID")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Lock your Bind wallet to keep your personal documents safe from prying eyes. Your privacy comes first.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
                .frame(height: 50)
        }
        .onAppear {
            if isSelected {
                breathe = true
            }
        }
        .onChange(of: isSelected) { selected in
            if selected {
                // Small delay to let the entry animation "settle" before the loop starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if isSelected {
                        breathe = true
                    }
                }
            } else {
                breathe = false
            }
        }
    }
}

// MARK: - Page 4: Final
struct FinalPageView: View {
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Shield / Check Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isSelected ? 1.0 : 0.5)
                    .opacity(isSelected ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: isSelected)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 0)
                    .scaleEffect(isSelected ? 1.0 : 0.5)
                    .opacity(isSelected ? 1.0 : 0.0)
                    .rotationEffect(.degrees(isSelected ? 0 : -30))
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: isSelected)
            }
            .frame(height: 350)
            .offset(y: -30)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Let’s get organised")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your personal document vault is ready. Experience the peace of mind that comes with total organisation.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
                .frame(height: 50)
        }
    }
}

import SwiftUI
import LocalAuthentication

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
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
                    WelcomePageView()
                        .tag(0)
                    
                    CentralizePageView()
                        .tag(1)
                    
                    FaceIDPageView()
                        .tag(2)
                    
                    FinalPageView()
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
                .padding(.bottom, 50)
            }
        }
    }
    
    var buttonText: String {
        switch currentPage {
        case 0: return "Get Started"
        case 2: return "Enable FaceID"
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
    @State private var showText = false
    @State private var innerRotation = 0.0
    @State private var outerRotation = 0.0
    
    // ORBIT CONFIGURATION
    let innerOrbitRadius: CGFloat = 130
    let innerIcons: [String] = [
        "calendar", 
        "person.circle.fill", 
        "creditcard.fill",
        "airplane",
        "ticket.fill",
        "pills.fill"
    ]
    
    let outerOrbitRadius: CGFloat = 260
    // Doubled icons as requested (Total 8)
    let outerIcons: [String] = [
        "map.fill", 
        "mappin.circle.fill", 
        "globe.americas.fill", 
        "star.fill",
        "tram.fill",
        "bed.double.fill",
        "car.fill",
        "ferry.fill"
    ]
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                
                // Solar System / Arch Animation
                ZStack {
                    // 1. Central Slick Card (The Sun/Center)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 70, height: 95)
                            .shadow(color: .white.opacity(0.4), radius: 30, x: 0, y: 0)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.black)
                    }
                    .offset(y: 40)
                    .zIndex(10)
                    
                    // 2. INNER ORBIT (Clockwise)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            .frame(width: innerOrbitRadius * 2, height: innerOrbitRadius * 2)
                        
                        ForEach(0..<innerIcons.count, id: \.self) { index in
                            let iconName = innerIcons[index]
                            let angle = Double(index) / Double(innerIcons.count) * 360.0
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                
                                Image(systemName: iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -innerOrbitRadius)
                            .rotationEffect(.degrees(angle))
                            // Counter-rotate icons to stay upright
                            .rotationEffect(.degrees(-innerRotation))
                        }
                    }
                    .rotationEffect(.degrees(innerRotation))
                    .offset(y: 40)
                    
                    // 3. OUTER ORBIT (Hemisphere, Anti-Clockwise)
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                            .frame(width: outerOrbitRadius * 2, height: outerOrbitRadius * 2)
                        
                        ForEach(0..<outerIcons.count, id: \.self) { index in
                            let iconName = outerIcons[index]
                            let angle = Double(index) / Double(outerIcons.count) * 360.0 + 45
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                
                                Image(systemName: iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -outerOrbitRadius)
                            .rotationEffect(.degrees(angle))
                            // Counter-rotate icons to stay upright
                            .rotationEffect(.degrees(-outerRotation))
                        }
                    }
                    .rotationEffect(.degrees(outerRotation))
                    .offset(y: 100)
                    .mask(
                        Rectangle()
                            .frame(width: 1000, height: outerOrbitRadius)
                            .offset(y: -outerOrbitRadius/2)
                    )
                }
                .frame(height: 350)
                .offset(y: showText ? -30 : 0)
                .animation(.easeInOut(duration: 0.8), value: showText)
                
                Spacer()
                    .frame(height: 40)
                
                // Text Content
                VStack(spacing: 16) {
                    Text("Welcome to Bind")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("The new home for life’s most important documents. Secure, organized, and always with you.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }
                .opacity(showText ? 1.0 : 0.0)
                .offset(y: showText ? 0 : 20)
                .animation(.easeOut(duration: 0.8), value: showText)
                
                Spacer()
                    .frame(height: 50)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            // FIX: Use a more robust animation trigger for repeatForever
            // Inner Orbit: Clockwise
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            // Outer Orbit: Anti-Clockwise
            withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
                outerRotation = -360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showText = true
            }
        }
    }
}

// MARK: - Page 2: Centralization / Ecosystem
struct CentralizePageView: View {
    @State private var appear = false
    
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
                    .opacity(appear ? 0.6 : 0)
                    .scaleEffect(appear ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appear)
                
                // Background Card 2
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.3))
                    .frame(width: 200, height: 140)
                    .rotationEffect(.degrees(12))
                    .offset(x: 40, y: -10)
                    .opacity(appear ? 0.8 : 0)
                    .scaleEffect(appear ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appear)
                
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
                    .offset(y: appear ? 0 : 40)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appear)
            }
            .frame(height: 350) 
            .offset(y: -30) 
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Stop the Scramble")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Passports, insurance, tickets, and IDs—centralized in one slick ecosystem. No more digging through photos.")
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
        .onAppear { appear = true }
    }
}

// MARK: - Page 3: FaceID
struct FaceIDPageView: View {
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // FaceID Icon Animation
            ZStack {
                // Glow
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .scaleEffect(appear ? 1.0 : 0.5)
                    .opacity(appear ? 1.0 : 0.0)
                
                // FaceID Icon (Static but animated entrance)
                Image(systemName: "faceid")
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundColor(.white)
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                    .scaleEffect(appear ? 1.0 : 0.8)
                    .opacity(appear ? 1.0 : 0.0)
            }
            .frame(height: 350)
            .offset(y: -30)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appear)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Secure with FaceID")
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
    }
}

// MARK: - Page 4: Final
struct FinalPageView: View {
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Shield / Check Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(appear ? 1.0 : 0.5)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: appear)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 0)
                    .scaleEffect(appear ? 1.0 : 0.5)
                    .opacity(appear ? 1.0 : 0.0)
                    .rotationEffect(.degrees(appear ? 0 : -30))
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: appear)
            }
            .frame(height: 350)
            .offset(y: -30)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text("Let’s Get Organized")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your personal document vault is ready. Experience the peace of mind that comes with total organization.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
                .frame(height: 50)
        }
        .onAppear { appear = true }
    }
}

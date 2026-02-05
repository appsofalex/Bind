import SwiftUI

struct AnneBirthdayCardAnimatedView: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    // Flip State
    @State private var yRotation: Double = 0
    @State private var isBackVisible = false
    
    // Animation States
    @State private var horseOffset: CGFloat = -400
    @State private var horseOpacity: Double = 0
    @State private var showMessage: Bool = false
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // BACK FACE (The Surprise)
                ZStack {
                    // Celebratory Background
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.96, blue: 0.93), Color(red: 1.0, green: 0.9, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("HAPPY BIRTHDAY MY BABY!")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(document.primaryColor)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Estate Icon
                        VStack(spacing: 15) {
                            Image(systemName: "house.and.flag.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                                .foregroundColor(document.primaryColor)
                                .shadow(radius: 5)
                            
                            Text("Lucknam Park")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Message text
                        if showMessage {
                            Text("We're going to Lucknam Park for your birthday! Pack your bags for a magical stay at this beautiful estate. I can't wait to celebrate with you chicken 🐥!")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .foregroundColor(.black.opacity(0.8))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                    
                    // Horses Animation
                    GeometryReader { geo in
                        HStack(spacing: 40) {
                            ForEach(0..<3) { i in
                                Image(systemName: "figure.equestrian.sports")
                                    .font(.system(size: 40))
                                    .foregroundColor(document.primaryColor.opacity(0.8))
                                    .offset(y: CGFloat(i * 15))
                            }
                        }
                        .opacity(horseOpacity)
                        .offset(x: horseOffset, y: geo.size.height * 0.6)
                    }
                }
                .cornerRadius(20)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // FRONT FACE
                DocumentCardView(document: document)
            }
        }
        .frame(height: isSelected ? 400 : 240)
        .rotation3DEffect(
            .degrees(yRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.8
        )
        .onTapGesture { onTap() }
        .onChange(of: isSelected) { newValue in
            if newValue {
                // FLIP OPEN
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 180
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = true
                    
                    // Trigger animations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Message fade in
                        withAnimation(.easeIn(duration: 0.8)) {
                            showMessage = true
                        }
                        
                        // Horses run across
                        horseOffset = -300
                        horseOpacity = 1.0
                        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 4.0)) {
                            horseOffset = 500
                        }
                        // Fade out horses at the end
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                horseOpacity = 0
                            }
                        }
                    }
                }
            } else {
                // FLIP CLOSE
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    yRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBackVisible = false
                    showMessage = false
                    horseOffset = -400
                    horseOpacity = 0
                }
            }
        }
    }
}

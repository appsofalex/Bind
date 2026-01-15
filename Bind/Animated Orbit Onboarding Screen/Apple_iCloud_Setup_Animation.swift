//
//  Apple_iCloud_Setup_Animation.swift
//  Apple iCloud Setup Animation
//
//  Created by Alex Walters on 15/01/2026.
//

import SwiftUI

struct AppleLoginAnimation: View {
    let logo: String
    let images: [String]
    
    var body: some View {
        ZStack {
            AnimatedLogoOrbit(
                images: images
            )
            
            // Central Icon styled for Bind
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 85, height: 85)
                    .shadow(color: .white.opacity(0.15), radius: 25)
                
                Image(systemName: logo)
                    .foregroundColor(.black)
                    .font(.system(size: 38, weight: .medium))
            }
            .offset(y: -5)
        }
    }
}

#Preview {
    AppleLoginAnimation(
        logo: "apple",
        images: ["messages", "app-store", "find-my", "music", "cloud", "files", "wallet", "photos"]
    )
}

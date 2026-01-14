//
//  BindApp.swift
//  Bind
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

@main
struct BindApp: App {
    // Persistent storage for onboarding state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    // This connects the App entry point to your main Wallet View
                    TravelDocsWalletView()
                        .transition(.opacity)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                }
            }
            // Force Dark Mode to maintain the "Sexy/Slick" aesthetic
            // regardless of the user's system settings.
            .preferredColorScheme(.dark)
            .animation(.easeInOut, value: hasCompletedOnboarding)
        }
    }
}

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
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .dark
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked: Bool
    
    init() {
        // On cold launch:
        // - If onboarding is complete AND Face ID is enabled, start locked.
        // - Otherwise, show content without an extra Face ID prompt.
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let isFaceIDEnabled = UserDefaults.standard.bool(forKey: "isFaceIDEnabled")
        _isUnlocked = State(initialValue: !(hasCompletedOnboarding && isFaceIDEnabled))
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                } else if isFaceIDEnabled && !isUnlocked {
                    LockScreenView {
                        withAnimation {
                            isUnlocked = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    // This connects the App entry point to your main Wallet View
                    TravelDocsWalletView()
                        .transition(.opacity)
                }
            }
            // Apply selected theme
            .preferredColorScheme(appTheme == .dark ? .dark : .light)
            .animation(.easeInOut(duration: 0.8), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.5), value: isUnlocked)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    // Lock the app when it goes to background if Face ID is enabled
                    if isFaceIDEnabled {
                        isUnlocked = false
                    }
                }
            }
        }
    }
}

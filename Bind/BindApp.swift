//
//  BindApp.swift
//  Bind
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

@main
struct BindApp: App {
    var body: some Scene {
        WindowGroup {
            // This connects the App entry point to your main Wallet View
            TravelDocsWalletView()
                // Force Dark Mode to maintain the "Sexy/Slick" aesthetic
                // regardless of the user's system settings.
                .preferredColorScheme(.dark)
        }
    }
}

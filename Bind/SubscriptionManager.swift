import SwiftUI
internal import Combine

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: "isProUser")
        }
    }
    
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: "isProUser")
    }
    
    func upgradeToPro() {
        // In a real app, this would trigger StoreKit purchase flow
        isPro = true
    }
    
    func downgradeToFree() {
        // For testing purposes
        isPro = false
    }
}

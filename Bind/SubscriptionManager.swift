import Foundation
import StoreKit
import SwiftUI
import UIKit
internal import Combine

/// Product ID for the yearly Pro subscription. Must match the subscription created in App Store Connect
/// (and in Configuration.storekit when using local testing).
enum ProProductID {
    static let yearly = "com.AlexCo.Bind.pro.subscription.yearly"
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    /// Pro status derived from current entitlements. Cached in UserDefaults for offline/launch.
    @Published private(set) var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: "isProUser")
        }
    }
    
    @Published var showUpgradeAnimation: Bool = false
    
    /// Loaded subscription product (nil until products are loaded or if unavailable).
    @Published private(set) var yearlyProduct: Product?
    
    /// Loading state for products and purchase.
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    
    /// User-facing error message (e.g. purchase failed, restore failed).
    @Published var purchaseError: String?
    
    private var transactionObserver: Task<Void, Error>?
    
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: "isProUser")
        transactionObserver = Task { await listenForTransactions() }
        Task { await updateProFromEntitlements() }
        Task { await loadProducts() }
    }
    
    deinit {
        transactionObserver?.cancel()
    }
    
    // MARK: - Products
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [ProProductID.yearly])
            yearlyProduct = products.first { $0.id == ProProductID.yearly }
        } catch {
            yearlyProduct = nil
        }
    }
    
    // MARK: - Entitlements
    
    /// Updates `isPro` from StoreKit current entitlements. Call after purchase, restore, and on transaction updates.
    func updateProFromEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == ProProductID.yearly {
                hasPro = true
                break
            }
        }
        if hasPro != isPro {
            isPro = hasPro
        }
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await updateProFromEntitlements()
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Purchase
    
    /// Starts the StoreKit purchase flow for the yearly Pro subscription. On success, updates isPro and shows upgrade animation.
    func purchasePro() async {
        // Ensure products are loaded before attempting to purchase.
        if yearlyProduct == nil {
            await loadProducts()
        }
        
        guard let product = yearlyProduct else {
            purchaseError = "Subscription is not available. Please try again later."
            return
        }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        
        do {
            // System presents the native payment sheet: user confirms with Face ID, Touch ID, or double‑click side button.
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateProFromEntitlements()
                    if isPro {
                        showUpgradeAnimation = true
                    }
                case .unverified(_, _):
                    purchaseError = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "Something went wrong."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    /// Restores previous purchases and updates isPro from entitlements.
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updateProFromEntitlements()
            if !isPro {
                purchaseError = "No previous Pro subscription found."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    /// Call this from the upgrade UI when user taps "Upgrade". Runs purchase then triggers notification permission flow on success.
    func upgradeToPro() {
        Task {
            await purchasePro()
            if isPro {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    NotificationManager.shared.requestPermission()
                }
            }
        }
    }
    
    /// For testing only. In production, Pro status is driven by StoreKit entitlements.
    func downgradeToFree() {
        isPro = false
    }
    
    /// Cancels the user's Pro subscription via Apple's subscription management UI.
    ///
    /// StoreKit does not provide an API that programmatically cancels a subscription on behalf
    /// of the user. The correct flow is to ask the user to cancel in Settings / App Store,
    /// while your app continues showing Pro until StoreKit entitlements update.
    func cancelProSubscription() {
        // Opens in App Store app when possible (subscription management), not Safari.
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

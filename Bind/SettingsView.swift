import SwiftUI
import LocalAuthentication
import StoreKit

struct SettingsView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    // App Preferences
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    @AppStorage("appTheme") private var appTheme: AppTheme = .dark
    
    // Alert State
    @State private var showDeleteConfirmation = false
    @State private var showUpgradeSheet = false
    
    @Environment(\.requestReview) private var requestReview
    
    // Subscription Manager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Subscription alert state (for restore purchases from Settings)
    @State private var showSubscriptionAlert = false
    @State private var subscriptionAlertMessage: String?
    
    /// Flip to `true` to show the Membership / Bind Pro section again.
    private let isMembershipUIVisible = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - SECURITY
                Section(header: Text("Security")) {
                    Toggle(isOn: Binding(
                        get: { isFaceIDEnabled },
                        set: { newValue in
                            if newValue {
                                authenticateFaceID()
                            } else {
                                isFaceIDEnabled = false
                            }
                        }
                    )) {
                        Label {
                            Text("Require Face ID")
                        } icon: {
                            Image(systemName: "faceid")
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // MARK: - PREFERENCES
                Section(header: Text("Preferences")) {
                    Picker(selection: $appTheme, label: Label {
                        Text("Appearance")
                    } icon: {
                        Image(systemName: appTheme == .dark ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(.gray)
                    }) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle(isOn: Binding(
                        get: { isHapticsEnabled },
                        set: { newValue in
                            isHapticsEnabled = newValue
                            if newValue {
                                HapticManager.shared.triggerSelection()
                            }
                        }
                    )) {
                        Label {
                            Text("Haptic Feedback")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - BIND PRO (hidden for now; Pro code kept intact)
                if isMembershipUIVisible {
                    Section {
                        if subscriptionManager.isPro {
                            NavigationLink(destination: BindProSubscriptionView(documents: documents)) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Bind Pro Active")
                                            .font(.headline)
                                        Text("Thank you for your support!")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                    Text("Bind Pro")
                                        .font(.headline)
                                }
                                
                                Text("Unlock customisable card colours, cloud sync, and quick access personalization.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    showUpgradeSheet = true
                                }) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                        
                                        if let error = subscriptionManager.purchaseError {
                                            subscriptionAlertMessage = error
                                            showSubscriptionAlert = true
                                            subscriptionManager.purchaseError = nil
                                        }
                                    }
                                }) {
                                    Text(subscriptionManager.isPurchasing ? "Restoring…" : "Restore Purchases")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Membership")
                    }
                }
                
                // MARK: - DATA
                Section(header: Text("Data")) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label {
                            Text("Delete All Cards")
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(documents.isEmpty)
                }
                
                // MARK: - ABOUT
                Section(header: Text("About")) {
                    Button {
                        requestReview()
                    } label: {
                        Label {
                            Text("Rate the App")
                        } icon: {
                            Image(systemName: "star")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/app/idXXXXXXXX")!, subject: Text("Check out Bind"), message: Text("I've been using Bind for my travel cards and documents — thought you might like it!")) {
                        Label {
                            Text("Recommend the App")
                        } icon: {
                            Image(systemName: "heart")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:alexwalterswork@gmail.com")!) {
                        Label {
                            Text("Support")
                        } icon: {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://docs.google.com/document/d/1mV-V1QHxxg9T1PQFawWqc3bGPjRIsiON/edit?usp=sharing&ouid=108114645063419842929&rtpof=true&sd=true")!) {
                        Label {
                            Text("Terms of Service")
                        } icon: {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://docs.google.com/document/d/1lhfu2p_Cl7_aNBGQYbF-2G_kkywbmhZr/edit?usp=sharing&ouid=108114645063419842929&rtpof=true&sd=true")!) {
                        Label {
                            Text("Privacy Policy")
                        } icon: {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Label {
                            Text("Version")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete All Cards?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This action cannot be undone. All your stored cards and documents will be permanently removed.")
            }
            .alert("Subscription", isPresented: $showSubscriptionAlert) {
                Button("OK") {
                    showSubscriptionAlert = false
                }
            } message: {
                if let error = subscriptionAlertMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showUpgradeSheet) {
                ProUpgradeView()
            }
        }
        .preferredColorScheme(appTheme == .dark ? .dark : .light)
    }
    
    private func authenticateFaceID() {
        let context = LAContext()
        var error: NSError?
        
        // We use .deviceOwnerAuthenticationWithBiometrics to specifically test for FaceID/TouchID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Confirm Face ID for app security"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isFaceIDEnabled = true
                    } else {
                        // If authentication fails or is cancelled, keep the toggle off
                        isFaceIDEnabled = false
                    }
                }
            }
        } else {
            // Biometrics not available on this device
            isFaceIDEnabled = false
            // You might want to show an alert here in a real app
        }
    }
    
    private func deleteAllData() {
        withAnimation {
            documents.removeAll()
        }
        // Save is handled automatically by ContentView's onChange
        dismiss()
    }
}

// Preview Helper
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(documents: .constant([]))
            // .preferredColorScheme(.dark)
    }
}

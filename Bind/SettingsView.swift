import SwiftUI
import LocalAuthentication

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
    
    // Subscription Manager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
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
                
                // MARK: - BIND PRO
                Section {
                    if subscriptionManager.isPro {
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
                        
                        Toggle(isOn: Binding(
                            get: { NotificationManager.shared.isAuthorized },
                            set: { newValue in
                                if newValue {
                                    NotificationManager.shared.requestPermission()
                                    // Reschedule if enabling
                                    NotificationManager.shared.scheduleExpiryNotifications(for: documents)
                                } else {
                                    // Open settings to disable manually since we can't toggle auth status programmatically
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        )) {
                            Label {
                                Text("Enable Expiry Alerts")
                            } icon: {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Card Colours")
                                    .foregroundColor(.primary)
                                Text("Edit any card to set its colour")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.gray)
                        }
                        
                        // Testing/Demo Button
                        Button("Demote to Free Plan (Test)") {
                            subscriptionManager.downgradeToFree()
                        }
                        .foregroundColor(.red)
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
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Membership")
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
                    Link(destination: URL(string: "https://www.example.com/privacy")!) {
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

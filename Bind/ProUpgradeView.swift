import SwiftUI

struct ProUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Feature list
    let features = [
        ("paintpalette.fill", "Customisable Card Colours", "Choose your own colours for each card. Personalise your wallet to match your style."),
        ("icloud.fill", "Cloud Sync", "Seamlessly sync your documents across all your Apple devices via iCloud."),
        ("bolt.fill", "Quick Access Personalization", "Customize your Quick Access view to keep your most vital info just a tap away."),
        ("bell.badge.fill", "Smart Expiry Alerts", "Get notified before your passports or visas expire. Never get caught out at the border.")
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.12))
                        .padding(.top, 40)
                    
                    Text("Upgrade to Bind Pro")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Unlock the full potential of your digital wallet.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(features, id: \.1) { icon, title, desc in
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.headline)
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer()
                
                // Purchase Button
                Button(action: {
                    subscriptionManager.upgradeToPro()
                    
                    // Request Notification Permission on upgrade with a 3-second delay
                    // so the user can see the Pro animation on the home screen first.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        NotificationManager.shared.requestPermission()
                    }
                    
                    dismiss()
                }) {
                    Text("Upgrade for $4.99/Year")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
                
                // Restore Purchase / Close
                Button("No Thanks") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
        }
    }
}

struct ProUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        ProUpgradeView()
    }
}

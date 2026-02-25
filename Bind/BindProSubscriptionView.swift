import SwiftUI

/// Sub-screen for managing Bind Pro subscription: status, expiry alerts, and card colours.
struct BindProSubscriptionView: View {
    let documents: [TravelDocument]
    @State private var showProBenefitsSheet = false
    
    var body: some View {
        Form {
            Section {
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
            
            Section {
                Toggle(isOn: Binding(
                    get: { NotificationManager.shared.isAuthorized },
                    set: { newValue in
                        if newValue {
                            NotificationManager.shared.requestPermission()
                            NotificationManager.shared.scheduleExpiryNotifications(for: documents)
                        } else {
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
            }
            
            Section {
                Button {
                    showProBenefitsSheet = true
                } label: {
                    Label {
                        Text("What's included")
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                Button("Demote to Free Plan (Test)") {
                    SubscriptionManager.shared.downgradeToFree()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Bind Pro")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProBenefitsSheet) {
            ProBenefitsSheetView()
        }
    }
}

// MARK: - Pro benefits sheet (reuses ProUpgradeView feature list)
private struct ProBenefitsSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    /// How to find or use each Pro feature (same order as ProUpgradeView.features).
    private static let benefitHowTo: [(path: String, pathAlternate: String?, steps: [String]?)] = [
        ("Main screen → Tap a card → Edit → Scroll down to Card Customisation → Card Colour", "Main screen → Add card (+) → Choose type → Scroll down to Card Customisation → Card Colour", nil),
        ("Sign in with the same Apple ID on each device. Your documents sync automatically when iCloud is enabled.", nil, nil),
        ("Settings → Membership → Bind Pro → Enable Expiry Alerts → Toggle on", nil, nil),
        ("Main screen → Tap a card → Edit → Scroll down to Card Customisation →  Card Icon", "Main screen → Add card (+) → Choose type → Scroll down to Card Customisation → Card Icon", nil)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(ProUpgradeView.features.enumerated()), id: \.offset) { index, feature in
                    let howTo = Self.benefitHowTo.indices.contains(index) ? Self.benefitHowTo[index] : (path: "", pathAlternate: nil as String?, steps: nil as [String]?)
                    NavigationLink(destination: ProBenefitDetailView(
                        title: feature.title,
                        icon: feature.icon,
                        path: howTo.path,
                        pathAlternate: howTo.pathAlternate,
                        steps: howTo.steps
                    )) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.headline)
                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("What's included")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Pro benefit detail (path / instructions)
private struct ProBenefitDetailView: View {
    let title: String
    let icon: String
    let path: String
    let pathAlternate: String?
    let steps: [String]?
    
    private func pathBlock(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 4)
                
                if let steps = steps, !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    pathBlock(path)
                    if let alt = pathAlternate, !alt.isEmpty {
                        Text("OR")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        pathBlock(alt)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("How to use")
        .navigationBarTitleDisplayMode(.inline)
    }
}

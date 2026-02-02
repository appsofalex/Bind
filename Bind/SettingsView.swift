import SwiftUI

struct SettingsView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    // App Preferences
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    
    // Alert State
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - SECURITY
                Section(header: Text("Security")) {
                    Toggle(isOn: $isFaceIDEnabled) {
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
                    Toggle(isOn: $isHapticsEnabled) {
                        Label {
                            Text("Haptic Feedback")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.orange)
                        }
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
                    Link(destination: URL(string: "https://www.example.com/privacy")!) {
                        Label {
                            Text("Privacy Policy")
                        } icon: {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.purple)
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
        }
        .preferredColorScheme(.dark) // Keep the app's dark aesthetic
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
            .preferredColorScheme(.dark)
    }
}

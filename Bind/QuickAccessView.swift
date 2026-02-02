import SwiftUI

struct QuickAccessView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    // Add Sheet State
    @State private var showAddSheet = false
    @State private var selectedAddType: TravelDocument.DocumentType? = nil
    @State private var prefilledTitle: String = "" 
    
    // Copy Feedback State
    @State private var copiedItem: String? = nil
    
    // Grid Layout Configuration
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Constant for square aspect ratio
    private let cardHeight: CGFloat = (UIScreen.main.bounds.width - 40 - 16) / 2
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        
                        // 1. BLOOD TYPE
                        QuickAccessCard(
                            title: "Blood\nType",
                            icon: "drop.fill",
                            color: .red,
                            data: bloodTypeData,
                            onAdd: {
                                prefilledTitle = "Blood Type"
                                startAdd(.medicalAlert)
                            },
                            onCopy: { copyToClipboard($0, label: "Blood Type") },
                            height: cardHeight
                        )
                        
                        // 2. PASSPORT NUMBER
                        QuickAccessCard(
                            title: "Passport\nNumber",
                            icon: "globe",
                            color: .blue,
                            data: passportNumberData,
                            onAdd: {
                                prefilledTitle = ""
                                startAdd(.passport)
                            },
                            onCopy: { copyToClipboard($0, label: "Passport Number") },
                            height: cardHeight
                        )
                        
                        // 3. NATIONAL INSURANCE / SSN
                        QuickAccessCard(
                            title: "National\nInsurance",
                            icon: "person.text.rectangle.fill",
                            color: .green,
                            data: nationalInsuranceData,
                            onAdd: {
                                prefilledTitle = "National Insurance"
                                startAdd(.idCard)
                            },
                            onCopy: { copyToClipboard($0, label: "National Insurance") },
                            height: cardHeight
                        )
                        
                        // 4. DRIVING LICENSE
                        QuickAccessCard(
                            title: "Driving\nLicense",
                            icon: "car.fill",
                            color: .orange,
                            data: drivingLicenseData,
                            onAdd: {
                                prefilledTitle = ""
                                startAdd(.driversLicense)
                            },
                            onCopy: { copyToClipboard($0, label: "License Number") },
                            height: cardHeight
                        )
                        
                        // 5. NHS / HEALTH NUMBER
                        QuickAccessCard(
                            title: "NHS\nNumber",
                            icon: "cross.fill",
                            color: .purple,
                            data: nhsNumberData,
                            onAdd: {
                                prefilledTitle = "NHS Number"
                                startAdd(.insurance)
                            },
                            onCopy: { copyToClipboard($0, label: "NHS Number") },
                            height: cardHeight
                        )
                        
                        // 6. EMERGENCY CONTACT
                        QuickAccessCard(
                            title: "Emergency\nContact",
                            icon: "phone.fill",
                            color: .pink,
                            data: emergencyContactData,
                            onAdd: {
                                prefilledTitle = "Emergency Contact"
                                startAdd(.medicalAlert)
                            },
                            onCopy: { copyToClipboard($0, label: "Emergency Contact") },
                            height: cardHeight
                        )
                    }
                    .padding(20)
                }
                
                // Copy Toast
                if let copied = copiedItem {
                    VStack {
                        Spacer()
                        Text("Copied \(copied)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.8))
                            .clipShape(Capsule())
                            .padding(.bottom, 30)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(100)
                }
            }
            .navigationTitle("Quick Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedAddType) { type in
                DocumentFormView(type: type, prefilledTitle: prefilledTitle) { newDoc in
                    documents.append(newDoc)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Logic
    
    func startAdd(_ type: TravelDocument.DocumentType) {
        selectedAddType = type
    }
    
    func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            copiedItem = label
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedItem = nil
            }
        }
    }
    
    // MARK: - Data Filtering
    
    var bloodTypeData: String? {
        documents.first(where: { $0.type == .medicalAlert && $0.title.localizedCaseInsensitiveContains("Blood Type") })?.subtitle 
        ?? documents.first(where: { $0.type == .medicalAlert && $0.holderName.contains("TYPE:") })?.holderName.components(separatedBy: "TYPE: ").last
    }
    
    var passportNumberData: String? {
        documents.first(where: { $0.type == .passport })?.detailValue
    }
    
    var nationalInsuranceData: String? {
        // Look for ID Card with title containing "National Insurance", "NI", "SSN"
        documents.first(where: { $0.type == .idCard && ($0.title.localizedCaseInsensitiveContains("National Insurance") || $0.title.localizedCaseInsensitiveContains("SSN") || $0.title.localizedCaseInsensitiveContains("NI")) })?.detailValue
    }
    
    var drivingLicenseData: String? {
        documents.first(where: { $0.type == .driversLicense })?.detailValue
    }
    
    var nhsNumberData: String? {
        // Look for Insurance or ID Card with "NHS" or "Health"
        if let doc = documents.first(where: { ($0.type == .insurance || $0.type == .idCard) && ($0.title.localizedCaseInsensitiveContains("NHS") || $0.title.localizedCaseInsensitiveContains("Health")) }) {
            return doc.detailValue
        }
        return nil
    }
    
    var emergencyContactData: String? {
        // 1. Dedicated Emergency Alert / Medical Card
        if let contact = documents.first(where: { $0.type == .medicalAlert }) {
            // New Priority: Explicit Phone Number
            if let phone = contact.emergencyPhoneNumber, !phone.isEmpty {
                return phone
            }
            // Fallback to detailValue if legacy or no specific phone field
            return contact.detailValue.isEmpty ? contact.subtitle : contact.detailValue
        }
        // 2. Insurance Emergency Phone
        if let ins = documents.first(where: { $0.type == .insurance }), let phone = ins.emergencyPhoneNumber, !phone.isEmpty {
             return phone
        }
        return nil
    }
}

// MARK: - Subviews

struct QuickAccessCard: View {
    let title: String
    let icon: String
    let color: Color
    let data: String?
    let onAdd: () -> Void
    let onCopy: (String) -> Void
    let height: CGFloat
    
    var body: some View {
        Button(action: {
            if let info = data, !info.isEmpty {
                onCopy(info)
            } else {
                onAdd()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 24))
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    if data != nil {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if let info = data, !info.isEmpty {
                    Text(info)
                        .font(.system(size: 19, weight: .bold, design: .rounded)) // Slightly adjusted for grid
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        Spacer()
                    }
                }
            }
            .padding(16)
            .frame(height: height)
            .background(Color(red: 0.18, green: 0.18, blue: 0.20))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button fade
    }
}

// Preview
struct QuickAccessView_Previews: PreviewProvider {
    static var previews: some View {
        QuickAccessView(documents: .constant([]))
            .preferredColorScheme(.dark)
    }
}

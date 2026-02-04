import SwiftUI

// MARK: - Tile Type Enum
enum QuickAccessTileType: String, CaseIterable, Identifiable {
    case bloodType
    case passportNumber
    case nationalInsurance
    case drivingLicense
    case nhsNumber
    case emergencyContact
    // New Options
    case flightNumber
    case rewardsNumber
    case vaccineDose
    case allergies
    case visaNumber
    case insurancePolicy
    case studentIDNumber
    case prescriptionRef
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .bloodType: return "Blood\nType"
        case .passportNumber: return "Passport\nNumber"
        case .nationalInsurance: return "National\nInsurance"
        case .drivingLicense: return "Driving\nLicense"
        case .nhsNumber: return "NHS\nNumber"
        case .emergencyContact: return "Emergency\nContact"
        case .flightNumber: return "Flight\nNumber"
        case .rewardsNumber: return "Rewards\nNumber"
        case .vaccineDose: return "Vaccine\nDose"
        case .allergies: return "Allergies"
        case .visaNumber: return "Visa\nNumber"
        case .insurancePolicy: return "Insurance\nPolicy"
        case .studentIDNumber: return "Student\nID"
        case .prescriptionRef: return "Prescription\nRef"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodType: return "drop.fill"
        case .passportNumber: return "globe"
        case .nationalInsurance: return "number.square.fill"
        case .drivingLicense: return "car.fill"
        case .nhsNumber: return "cross.fill"
        case .emergencyContact: return "phone.fill"
        case .flightNumber: return "airplane"
        case .rewardsNumber: return "star.fill"
        case .vaccineDose: return "syringe.fill"
        case .allergies: return "exclamationmark.shield.fill"
        case .visaNumber: return "checkmark.seal.fill"
        case .insurancePolicy: return "cross.case.fill"
        case .studentIDNumber: return "graduationcap.fill"
        case .prescriptionRef: return "pills.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bloodType: return .red
        case .passportNumber: return .blue
        case .nationalInsurance: return .green
        case .drivingLicense: return .orange
        case .nhsNumber: return .purple
        case .emergencyContact: return .pink
        case .flightNumber: return .cyan
        case .rewardsNumber: return .mint
        case .vaccineDose: return .teal
        case .allergies: return .red
        case .visaNumber: return .orange
        case .insurancePolicy: return .red
        case .studentIDNumber: return .blue
        case .prescriptionRef: return .green
        }
    }
    
    // Helper to determine which document type creates this data
    var associatedDocType: TravelDocument.DocumentType {
        switch self {
        case .bloodType, .emergencyContact, .allergies: return .medicalAlert
        case .passportNumber: return .passport
        case .nationalInsurance: return .nationalInsurance
        case .nhsNumber: return .idCard
        case .drivingLicense: return .driversLicense
        case .flightNumber: return .boardingPass
        case .rewardsNumber: return .rewardsCard
        case .vaccineDose: return .vaccineRecord
        case .visaNumber: return .visa
        case .insurancePolicy: return .insurance
        case .studentIDNumber: return .studentID
        case .prescriptionRef: return .prescription
        }
    }
    
    var prefilledTitle: String {
        switch self {
        case .bloodType: return "Blood Type"
        case .nationalInsurance: return "National Insurance"
        case .nhsNumber: return "NHS Number"
        case .emergencyContact: return "Emergency Contact"
        case .allergies: return "Allergies"
        case .visaNumber: return "Visa Number"
        case .insurancePolicy: return "Policy Number"
        case .studentIDNumber: return "Student ID"
        case .prescriptionRef: return "Prescription Ref"
        default: return ""
        }
    }
}

struct QuickAccessView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Add Sheet State
    @State private var showAddSheet = false
    @State private var selectedAddType: TravelDocument.DocumentType? = nil
    @State private var prefilledTitle: String = "" 
    
    // Edit Mode State
    @State private var isEditing = false
    @State private var showProUpgrade = false
    @State private var showTileReplacement = false
    @State private var tileIndexToReplace: Int? = nil
    
    // Persistence for Tiles
    @AppStorage("activeQuickAccessTiles") var activeTilesRaw: String = "passportNumber,bloodType,vaccineDose,nationalInsurance,drivingLicense,emergencyContact"
    
    var activeTiles: [QuickAccessTileType] {
        get {
            let defaults: [QuickAccessTileType] = [.passportNumber, .bloodType, .vaccineDose, .nationalInsurance, .drivingLicense, .emergencyContact]
            let stored = activeTilesRaw.split(separator: ",").compactMap { QuickAccessTileType(rawValue: String($0)) }
            return stored.isEmpty ? defaults : stored
        }
        nonmutating set {
            activeTilesRaw = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
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
                Group {
                    if colorScheme == .dark {
                        Color(red: 0.11, green: 0.11, blue: 0.12)
                    } else {
                        Color(red: 0.96, green: 0.96, blue: 0.97)
                    }
                }.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(activeTiles.enumerated()), id: \.offset) { index, tile in
                            ZStack {
                                QuickAccessCard(
                                    title: tile.title,
                                    icon: tile.icon,
                                    color: tile.color,
                                    data: getData(for: tile),
                                    isEditing: isEditing,
                                    onAdd: {
                                        if isEditing {
                                            tileIndexToReplace = index
                                            showTileReplacement = true
                                        } else {
                                            prefilledTitle = tile.prefilledTitle
                                            startAdd(tile.associatedDocType)
                                        }
                                    },
                                    onCopy: { 
                                        if isEditing {
                                            tileIndexToReplace = index
                                            showTileReplacement = true
                                        } else {
                                            copyToClipboard($0, label: tile.title.replacingOccurrences(of: "\n", with: " "))
                                        }
                                    },
                                    height: cardHeight
                                )
                            }
                        }
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
            .navigationTitle(isEditing ? "Edit Tiles" : "Quick Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if subscriptionManager.isPro {
                            withAnimation {
                                isEditing.toggle()
                            }
                        } else {
                            showProUpgrade = true
                        }
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(isEditing ? .bold : .regular)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                         // Empty space to balance
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(item: $selectedAddType) { type in
                DocumentFormView(type: type, prefilledTitle: prefilledTitle) { newDoc in
                    documents.append(newDoc)
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showTileReplacement) {
                TileReplacementView(selectedTile: Binding(
                    get: { 
                        if let index = tileIndexToReplace, index < activeTiles.count {
                            return activeTiles[index]
                        }
                        return .bloodType // fallback
                    },
                    set: { newTile in
                        if let index = tileIndexToReplace {
                            var current = activeTiles
                            current[index] = newTile
                            activeTiles = current
                        }
                    }
                ))
            }
        }
        // .preferredColorScheme(.dark)
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
    
    func getData(for tile: QuickAccessTileType) -> String? {
        switch tile {
        case .bloodType:
            return documents.first(where: { $0.type == .medicalAlert && $0.title.localizedCaseInsensitiveContains("Blood Type") })?.subtitle 
            ?? documents.first(where: { $0.type == .medicalAlert && $0.holderName.contains("TYPE:") })?.holderName.components(separatedBy: "TYPE: ").last
            
        case .passportNumber:
            return documents.first(where: { $0.type == .passport })?.detailValue
            
        case .nationalInsurance:
            if let niDoc = documents.first(where: { $0.type == .nationalInsurance }) {
                return niDoc.detailValue
            }
            return documents.first(where: { $0.type == .idCard && ($0.title.localizedCaseInsensitiveContains("National Insurance") || $0.title.localizedCaseInsensitiveContains("SSN") || $0.title.localizedCaseInsensitiveContains("NI")) })?.detailValue
            
        case .drivingLicense:
            return documents.first(where: { $0.type == .driversLicense })?.detailValue
            
        case .nhsNumber:
             if let doc = documents.first(where: { ($0.type == .insurance || $0.type == .idCard) && ($0.title.localizedCaseInsensitiveContains("NHS") || $0.title.localizedCaseInsensitiveContains("Health")) }) {
                return doc.detailValue
            }
            return nil
            
        case .emergencyContact:
            if let contact = documents.first(where: { $0.type == .medicalAlert }) {
                if let phone = contact.emergencyPhoneNumber, !phone.isEmpty { return phone }
                return contact.detailValue.isEmpty ? contact.subtitle : contact.detailValue
            }
            if let ins = documents.first(where: { $0.type == .insurance }), let phone = ins.emergencyPhoneNumber, !phone.isEmpty {
                 return phone
            }
            return nil
            
        case .flightNumber:
            return documents.first(where: { $0.type == .boardingPass })?.subtitle // Usually flight number is in subtitle
            
        case .rewardsNumber:
            return documents.first(where: { $0.type == .rewardsCard })?.detailValue
            
        case .vaccineDose:
            return documents.first(where: { $0.type == .vaccineRecord })?.dose
            
        case .allergies:
            return documents.first(where: { $0.type == .medicalAlert && $0.title.localizedCaseInsensitiveContains("Allergies") })?.subtitle
            
        case .visaNumber:
            return documents.first(where: { $0.type == .visa })?.detailValue
            
        case .insurancePolicy:
            return documents.first(where: { $0.type == .insurance })?.detailValue
            
        case .studentIDNumber:
            return documents.first(where: { $0.type == .studentID })?.detailValue
            
        case .prescriptionRef:
            return documents.first(where: { $0.type == .prescription })?.detailValue
        }
    }
}

// Subviews

struct TileReplacementView: View {
    @Binding var selectedTile: QuickAccessTileType
    @Environment(\.dismiss) var dismiss
    
    let allTiles = QuickAccessTileType.allCases
    
    var body: some View {
        NavigationView {
            List(allTiles) { tile in
                Button(action: {
                    selectedTile = tile
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: tile.icon)
                            .foregroundColor(tile.color)
                            .frame(width: 30)
                        Text(tile.title.replacingOccurrences(of: "\n", with: " "))
                            .foregroundColor(.primary)
                        Spacer()
                        if tile == selectedTile {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Replace Tile")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct QuickAccessCard: View {
    let title: String
    let icon: String
    let color: Color
    let data: String?
    let isEditing: Bool
    let onAdd: () -> Void
    let onCopy: (String) -> Void
    let height: CGFloat
    
    @State private var jiggleAmount: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                if isEditing {
                    onAdd()
                } else if let info = data, !info.isEmpty {
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
                        
                        if data != nil && !isEditing {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    if let info = data, !info.isEmpty {
                        Text(info)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .blur(radius: isEditing ? 2 : 0) // Blur content in edit mode
                    } else {
                        HStack {
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.3))
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .frame(height: height)
                .background(colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white)
                .cornerRadius(20)
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .opacity(isEditing ? 0.8 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Pencil Overlay
            if isEditing {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 2)
                        .frame(width: 28, height: 28)
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .rotationEffect(.degrees(jiggleAmount))
        .offset(x: jiggleAmount / 2, y: -jiggleAmount / 2)
        .onChange(of: isEditing) { newValue in
            if newValue {
                // Random delay to desync jiggles for a more natural look
                let delay = Double.random(in: 0...0.1)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    jiggleAmount = -1.2
                    withAnimation(.linear(duration: 0.12).repeatForever(autoreverses: true)) {
                        jiggleAmount = 1.2
                    }
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    jiggleAmount = 0
                }
            }
        }
    }
}

// Preview
struct QuickAccessView_Previews: PreviewProvider {
    static var previews: some View {
        QuickAccessView(documents: .constant([]))
            // .preferredColorScheme(.dark)
    }
}

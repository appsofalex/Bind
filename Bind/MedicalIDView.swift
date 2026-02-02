import SwiftUI

struct MedicalIDView: View {
    let documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    // Filtered Computeds
    private var medicalAlerts: [TravelDocument] {
        documents.filter { $0.type == .medicalAlert }
    }
    
    private var prescriptions: [TravelDocument] {
        documents.filter { $0.type == .prescription }
    }
    
    private var vaccinations: [TravelDocument] {
        documents.filter { $0.type == .vaccineRecord }
    }
    
    private var insurance: [TravelDocument] {
        documents.filter { $0.type == .insurance }
    }
    
    private var hasAnyMedicalData: Bool {
        !medicalAlerts.isEmpty || !prescriptions.isEmpty || !vaccinations.isEmpty || !insurance.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Group {
                if !hasAnyMedicalData {
                    VStack(spacing: 20) {
                        Image(systemName: "staroflife.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("No Medical Info")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add any Medical card from the Health section using the '+' button to see a summary here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        // 1. MEDICAL ALERTS (Critical Info)
                        if !medicalAlerts.isEmpty {
                            Section(header: Text("Emergency Alerts").foregroundColor(.red)) {
                                ForEach(medicalAlerts) { doc in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(doc.title) // e.g. "Penicillin Allergy"
                                            .font(.headline)
                                        if !doc.subtitle.isEmpty {
                                            Text(doc.subtitle) // e.g. "Severe Reaction"
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        if !doc.detailValue.isEmpty {
                                            Text(doc.detailValue) // e.g. "Notes..."
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        
                        // 2. PRESCRIPTIONS
                        if !prescriptions.isEmpty {
                            Section(header: Text("Medications")) {
                                ForEach(prescriptions) { doc in
                                    HStack {
                                        Image(systemName: "pills.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text(doc.title)
                                                .font(.headline)
                                            Text(doc.subtitle) // Dosage / Frequency
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 3. VACCINATIONS
                        if !vaccinations.isEmpty {
                            Section(header: Text("Vaccinations")) {
                                ForEach(vaccinations, id: \.id) { doc in
                                    HStack {
                                        Image(systemName: "syringe.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading) {
                                            Text(doc.title)
                                                .font(.headline)
                                            if let date = doc.issueDate {
                                                Text("Date: \(date.formatted(date: .long, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 4. INSURANCE
                        if !insurance.isEmpty {
                            Section(header: Text("Insurance")) {
                                ForEach(insurance) { doc in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(doc.title) // Provider Name
                                            .font(.headline)
                                        
                                        HStack {
                                            Text("Policy:")
                                                .foregroundColor(.secondary)
                                            Text(doc.subtitle)
                                        }
                                        .font(.subheadline)
                                        
                                        if let group = doc.groupNumber, !group.isEmpty {
                                            HStack {
                                                Text("Group:")
                                                    .foregroundColor(.secondary)
                                                Text(group)
                                            }
                                            .font(.caption)
                                        }
                                        
                                        if let phone = doc.emergencyPhoneNumber, !phone.isEmpty {
                                            HStack {
                                                Image(systemName: "phone.fill")
                                                    .font(.caption)
                                                Text(phone)
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.top, 2)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Medical ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Preview
struct MedicalIDView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalIDView(documents: [])
            .preferredColorScheme(.dark)
    }
}

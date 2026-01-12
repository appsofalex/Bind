import SwiftUI
import PhotosUI

// A helper struct to make UIImage identifiable for use with .sheet(item:).
fileprivate struct CroppableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - NEW: ADD DOCUMENT VIEW & FORM
struct DocumentFormView: View {
    let type: TravelDocument.DocumentType
    let onSave: (TravelDocument) -> Void
    let existingID: UUID? // Stores ID if we are editing
    
    @Environment(\.dismiss) var dismiss
    
    // Form Fields
    @State private var title: String
    @State private var subtitle: String
    @State private var holderName: String
    @State private var detailValue: String
    
    // Specific Dropdowns
    @State private var selectedBloodType: String
    @State private var selectedAllergy: String
    @State private var selectedVaccine: String
    @State private var selectedUniversity: String
    @State private var selectedAirline: String
    
    // PASSPORT & INSURANCE & LICENSE SPECIFIC FIELDS
    @State private var nationality: String
    @State private var birthDate: Date
    @State private var issueDate: Date
    @State private var expiryDate: Date
    
    // BOARDING PASS SPECIFIC FIELDS
    @State private var origin: String
    @State private var gate: String
    @State private var seat: String
    @State private var flightClass: String
    @State private var flightDate: Date
    @State private var boardingTime: Date
    
    // INSURANCE SPECIFIC FIELDS
    @State private var groupNumber: String
    @State private var emergencyPhoneNumber: String
    
    // DRIVER'S LICENSE SPECIFIC FIELDS
    @State private var address: String
    @State private var licenseClass: String
    @State private var restrictions: String
    @State private var endorsements: String
    @State private var height: String
    @State private var eyeColor: String
    @State private var documentImage: Data?
    
    // Image Picker & Cropper State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageToCrop: CroppableImage?
    
    // MARK: - DATA COLLECTIONS
    let bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let vaccines = ["COVID-19", "Influenza", "Yellow Fever", "Tetanus", "Hepatitis B", "Measles"]
    let visaTypes = ["Tourist Visa", "Business Visa", "Student Visa", "Work Visa", "Transit Visa", "Investor Visa", "Spouse Visa", "Visitor Visa"]
    let insuranceTypes = ["Travel", "Health", "Auto", "Dental", "Life", "Home & Contents"]
    
    // Static list for UK Driver's License classes
    let licenseClasses = ["Category B (Car)", "Category A (Motorcycle)", "Category C (Large Goods)", "Category D (Bus)", "Provisional"]

    let countries = [
        "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan",
        "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
        "Cabo Verde", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo (Congo-Brazzaville)", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czechia",
        "Denmark", "Djibouti", "Dominica", "Dominican Republic",
        "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia",
        "Fiji", "Finland", "France",
        "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana",
        "Haiti", "Honduras", "Hungary",
        "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy",
        "Jamaica", "Japan", "Jordan",
        "Kazakhstan", "Kenya", "Kiribati", "Kuwait", "Kyrgyzstan",
        "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg",
        "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar",
        "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Korea", "North Macedonia", "Norway",
        "Oman",
        "Pakistan", "Palau", "Palestine State", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal",
        "Qatar",
        "Romania", "Russia", "Rwanda",
        "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname",
        "Sweden", "Switzerland", "Syria",
        "Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu",
        "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
        "Vanuatu", "Venezuela", "Vietnam",
        "Yemen",
        "Zambia", "Zimbabwe"
    ]
    
    // Segmented Airlines by Country
    let airlineSegments: [(country: String, airlines: [String])] = [
        ("United Kingdom", ["British Airways", "easyJet", "Virgin Atlantic"]),
        ("United States", ["American Airlines", "Delta", "United"]),
        ("Australia", ["Qantas"]),
        ("Canada", ["Air Canada"]),
        ("China", ["Air China"]),
        ("Germany", ["Lufthansa"]),
        ("Ireland", ["Ryanair"]),
        ("Japan", ["Japan Airlines"]),
        ("Qatar", ["Qatar Airways"]),
        ("Singapore", ["Singapore Airlines"]),
        ("UAE", ["Emirates"])
    ]
    
    // AIRPORT DATA
    let airports = [
        ("ATL", "Hartsfield-Jackson Atlanta"),
        ("JFK", "New York John F. Kennedy"),
        ("LAX", "Los Angeles International"),
        ("ORD", "Chicago O'Hare"),
        ("DFW", "Dallas/Fort Worth"),
        ("DEN", "Denver International"),
        ("SFO", "San Francisco International"),
        ("YYZ", "Toronto Pearson"),
        ("YVR", "Vancouver International"),
        ("LHR", "London Heathrow"),
        ("LGW", "London Gatwick"),
        ("LTN", "London Luton"),
        ("STN", "London Stansted"),
        ("LCY", "London City"),
        ("SEN", "London Southend"),
        ("MAN", "Manchester"),
        ("EDI", "Edinburgh"),
        ("BRS", "Bristol"),
        ("CDG", "Paris Charles de Gaulle"),
        ("AMS", "Amsterdam Schiphol"),
        ("FRA", "Frankfurt Airport"),
        ("IST", "Istanbul Airport"),
        ("MAD", "Madrid-Barajas"),
        ("DXB", "Dubai International"),
        ("DOH", "Doha Hamad International"),
        ("AUH", "Abu Dhabi International"),
        ("HND", "Tokyo Haneda"),
        ("NRT", "Tokyo Narita"),
        ("HKG", "Hong Kong International"),
        ("SIN", "Singapore Changi"),
        ("ICN", "Seoul Incheon"),
        ("PEK", "Beijing Capital"),
        ("PVG", "Shanghai Pudong"),
        ("BKK", "Bangkok Suvarnabhumi"),
        ("DEL", "Delhi Indira Gandhi"),
        ("SYD", "Sydney Kingsford Smith"),
        ("MEL", "Melbourne Tullamarine"),
        ("AKL", "Auckland Airport"),
        ("GRU", "São Paulo Guarulhos"),
        ("BOG", "El Dorado International"),
        ("JNB", "O.R. Tambo Johannesburg"),
        ("CAI", "Cairo International"),
        ("MUC", "Munich"),
        ("ZRH", "Zurich"),
        ("VIE", "Vienna"),
        ("DUB", "Dublin"),
        ("BCN", "Barcelona El Prat"),
        ("FCO", "Rome Fiumicino"),
        ("MXP", "Milan Malpensa"),
        ("LIN", "Milan Linate"),
        ("LIS", "Lisbon"),
        ("CPH", "Copenhagen"),
        ("ARN", "Stockholm Arlanda"),
        ("OSL", "Oslo Gardermoen"),
        ("HEL", "Helsinki"),
        ("WAW", "Warsaw Chopin"),
        ("ATH", "Athens"),
        ("BUD", "Budapest"),
        ("PRG", "Prague"),
        ("FAO", "Faro"),
        ("NCE", "Nice"),
        ("ALC", "Alicante"),
        ("PMI", "Palma de Mallorca")
    ]
    
    // AIRPORT FILTER LOGIC
    func filteredAirports(for query: String) -> [(code: String, name: String)] {
        if query.isEmpty { return [] }
        
        let matches = airports.filter { code, name in
            code.localizedCaseInsensitiveContains(query) || name.localizedCaseInsensitiveContains(query)
        }
        
        if matches.contains(where: { "\( $0.1 ) (\( $0.0 ))" == query }) {
            return []
        }
        
        return matches.sorted { $0.1 < $1.1 }.map { (code: $0.0, name: $0.1) }
    }
    
    // Helper to determine if we show the photo upload section
    private var shouldShowPhotoUpload: Bool {
        return [.passport, .driversLicense, .studentID, .idCard].contains(type)
    }
    
    // Initialize default values based on type OR existing document
    init(type: TravelDocument.DocumentType? = nil,
         document: TravelDocument? = nil,
         onSave: @escaping (TravelDocument) -> Void) {
        
        self.onSave = onSave
        
        // Initialize all @State properties
        _title = State(initialValue: "")
        _subtitle = State(initialValue: "")
        _holderName = State(initialValue: "")
        _detailValue = State(initialValue: "")
        _selectedBloodType = State(initialValue: "A+")
        _selectedAllergy = State(initialValue: "None")
        _selectedVaccine = State(initialValue: "COVID-19")
        _selectedUniversity = State(initialValue: "State Univ")
        _selectedAirline = State(initialValue: "British Airways")
        _nationality = State(initialValue: "")
        _birthDate = State(initialValue: Date())
        _issueDate = State(initialValue: Date())
        _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 10))
        _origin = State(initialValue: "")
        _gate = State(initialValue: "")
        _seat = State(initialValue: "")
        _flightClass = State(initialValue: "Economy")
        _flightDate = State(initialValue: Date())
        _boardingTime = State(initialValue: Date())
        _groupNumber = State(initialValue: "")
        _emergencyPhoneNumber = State(initialValue: "")
        _address = State(initialValue: "")
        _licenseClass = State(initialValue: "")
        _restrictions = State(initialValue: "")
        _endorsements = State(initialValue: "")
        _height = State(initialValue: "")
        _eyeColor = State(initialValue: "")
        _documentImage = State(initialValue: nil)
        
        if let doc = document {
            // EDIT MODE
            self.type = doc.type
            self.existingID = doc.id
            
            _title = State(initialValue: doc.title)
            _subtitle = State(initialValue: doc.subtitle)
            _holderName = State(initialValue: doc.holderName)
            _detailValue = State(initialValue: doc.detailValue)
            _nationality = State(initialValue: doc.nationality ?? "")
            _selectedAirline = State(initialValue: doc.airline.isEmpty ? "British Airways" : doc.airline)
            
            if let dob = doc.birthDate { _birthDate = State(initialValue: dob) }
            if let iss = doc.issueDate { _issueDate = State(initialValue: iss) }
            if let exp = doc.expiryDate { _expiryDate = State(initialValue: exp) }
            
            _origin = State(initialValue: doc.origin ?? "")
            _gate = State(initialValue: doc.gate ?? "")
            _seat = State(initialValue: doc.seat ?? "")
            _flightClass = State(initialValue: doc.flightClass ?? "Economy")
            if let fd = doc.flightDate { _flightDate = State(initialValue: fd) }
            if let bt = doc.boardingTime { _boardingTime = State(initialValue: bt) }
            
            _groupNumber = State(initialValue: doc.groupNumber ?? "")
            _emergencyPhoneNumber = State(initialValue: doc.emergencyPhoneNumber ?? "")
            
            _address = State(initialValue: doc.address ?? "")
            _licenseClass = State(initialValue: doc.licenseClass ?? "")
            _restrictions = State(initialValue: doc.restrictions ?? "")
            _endorsements = State(initialValue: doc.endorsements ?? "")
            _height = State(initialValue: doc.height ?? "")
            _eyeColor = State(initialValue: doc.eyeColor ?? "")
            _documentImage = State(initialValue: doc.documentImageData)
            
            if doc.type == .medicalAlert {
                if let bloodTypeRange = doc.holderName.range(of: "TYPE: ") {
                    _selectedBloodType = State(initialValue: String(doc.holderName[bloodTypeRange.upperBound...]))
                }
            } else if doc.type == .vaccineRecord {
                _selectedVaccine = State(initialValue: doc.subtitle.capitalized)
            }
            
        } else {
            // ADD MODE
            let targetType = type ?? .passport
            self.type = targetType
            self.existingID = nil
            
            switch targetType {
            case .passport:
                _title = State(initialValue: "United Kingdom")
                _nationality = State(initialValue: "United Kingdom")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 10))
            case .visa:
                _title = State(initialValue: "United States")
                _subtitle = State(initialValue: "Tourist Visa")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 5))
            case .insurance:
                _subtitle = State(initialValue: "Travel")
                _issueDate = State(initialValue: Date())
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60))
            case .driversLicense:
                _title = State(initialValue: "United Kingdom")
                _subtitle = State(initialValue: "DRIVER LICENSE")
                _licenseClass = State(initialValue: "Category B (Car)")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 5))
            case .studentID:
                _subtitle = State(initialValue: "Student ID")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 4))
            case .prescription:
                _title = State(initialValue: "Pharmacy")
                _subtitle = State(initialValue: "RX PRESCRIPTION")
            case .vaccineRecord:
                _title = State(initialValue: "CDC / NHS")
                _subtitle = State(initialValue: "VACCINATION")
            case .medicalAlert:
                _title = State(initialValue: "Medical Alert")
                _subtitle = State(initialValue: "EMERGENCY INFO")
                _holderName = State(initialValue: "TYPE: A+")
            case .birthCertificate:
                _title = State(initialValue: "Birth Certificate")
                _subtitle = State(initialValue: "OFFICIAL RECORD")
            case .marriageCertificate:
                _title = State(initialValue: "Marriage Certificate")
                _subtitle = State(initialValue: "OFFICIAL RECORD")
            default:
                break
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                documentDetailsSection
                personalInfoSection
                
                // Moved Photo Upload out of personalInfoSection.
                // This ensures the fields above it (like Date of Expiry) get rounded corners at the bottom.
                if shouldShowPhotoUpload {
                    documentPhotoUploadDivider
                    
                    Section {
                        documentPhotoUploadArea
                    }
                }
            }
            .navigationTitle(existingID != nil ? "Edit \(type.displayName)" : "Add \(type.displayName)")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(existingID != nil ? "Save" : "Add") {
                    saveDocument()
                    dismiss()
                }
            )
            .sheet(item: $imageToCrop) { item in
                ImageCropperView(image: item.image) { croppedImage in
                    documentImage = croppedImage.jpegData(compressionQuality: 0.8)
                }
            }
            .onChange(of: selectedPhotoItem) {
                Task {
                    if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            imageToCrop = CroppableImage(image: image)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var documentDetailsSection: some View {
        Section(header: Text("Document Details")) {
            switch type {
            case .medicalAlert:
                Picker("Blood Type", selection: $selectedBloodType) {
                    ForEach(bloodTypes, id: \.self) { Text($0) }
                }
                TextField("Allergies", text: $holderName)
                    .textInputAutocapitalization(.sentences)
                    .overlay(
                        Text("e.g. Peanuts, Penicillin").foregroundColor(.gray.opacity(0.5)).allowsHitTesting(false).opacity(holderName.isEmpty ? 1 : 0),
                        alignment: .leading
                    )
            case .vaccineRecord:
                 Picker("Vaccine Type", selection: $selectedVaccine) {
                     ForEach(vaccines, id: \.self) { Text($0) }
                 }
                 TextField("Date / Dose", text: $detailValue)
            case .boardingPass:
                 Picker("Airline", selection: $selectedAirline) {
                     ForEach(airlineSegments, id: \.country) { segment in
                         Section(header: Text(segment.country)) {
                             ForEach(segment.airlines, id: \.self) { airline in
                                 Text(airline).tag(airline)
                             }
                         }
                     }
                 }
                 
                AirportSelectionField(
                    title: "Origin (Type code or city)",
                    selection: $origin,
                    airports: filteredAirports(for: origin)
                ) { name, code in
                    origin = "\(name) (\(code))"
                }

                AirportSelectionField(
                    title: "Destination (Type code or city)",
                    selection: $title,
                    airports: filteredAirports(for: title)
                ) { name, code in
                    title = "\(name) (\(code))"
                }

                HStack {
                    TextField("Gate", text: $gate)
                    Divider()
                    TextField("Seat", text: $seat)
                }
                
                Picker("Class", selection: $flightClass) {
                    Text("Economy").tag("Economy")
                    Text("Premium Economy").tag("Premium Economy")
                    Text("Business").tag("Business")
                    Text("First").tag("First")
                }
                
                DatePicker("Flight Date", selection: $flightDate, displayedComponents: .date)
                DatePicker("Flight Time", selection: $boardingTime, displayedComponents: .hourAndMinute)
                
            case .passport:
                Picker("Country", selection: $title) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .onChange(of: title) { newValue in
                    nationality = newValue
                }
            case .visa:
                Picker("Country", selection: $title) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                Picker("Visa Type", selection: $subtitle) {
                    ForEach(visaTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            case .insurance:
                TextField("Provider Name", text: $title)
                    .textInputAutocapitalization(.words)
                Picker("Plan Type", selection: $subtitle) {
                    ForEach(insuranceTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            case .driversLicense:
                Picker("Issuing Country", selection: $title) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                Picker("License Class", selection: $licenseClass) {
                    ForEach(licenseClasses, id: \.self) { aClass in
                        Text(aClass).tag(aClass)
                    }
                }
            
            case .studentID, .idCard, .prescription, .birthCertificate, .marriageCertificate:
                TextField(type == .studentID ? "University name" : "Title (e.g. Country, State)", text: $title)
                    .textInputAutocapitalization(.words)
                TextField("Subtitle (e.g. License Type)", text: $subtitle)
                    .textInputAutocapitalization(type == .studentID ? .sentences : .characters)
            }
        }
    }
    
    private var personalInfoSection: some View {
        Section(header: Text("Personal Info")) {
            switch type {
            case .medicalAlert:
                TextField("Emergency Contact", text: $detailValue)
                    .textInputAutocapitalization(.words)
            case .passport:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Passport Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
                TextField("Nationality", text: $nationality)
                    .textInputAutocapitalization(.words)
                
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)

            case .boardingPass:
                 TextField("Passenger Name", text: $holderName)
                     .textInputAutocapitalization(.words)
                 TextField("Flight Number", text: $detailValue)
                     .textInputAutocapitalization(.characters)
                     .onChange(of: detailValue) { newValue in
                         detailValue = newValue.uppercased()
                     }
            case .insurance:
                TextField("Policy Holder Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Policy Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                TextField("Group Number (Optional)", text: $groupNumber)
                    .textInputAutocapitalization(.characters)
                TextField("Emergency Contact Number", text: $emergencyPhoneNumber)
                    .keyboardType(.phonePad)
                
                DatePicker("Coverage Start Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Coverage End Date", selection: $expiryDate, displayedComponents: .date)
            
            case .driversLicense:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("License Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                TextField("Address", text: $address, axis: .vertical)
                    .lineLimit(3)
                
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)

            case .studentID, .idCard:
                TextField("Your Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField(getDetailLabel(), text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
                
                if type == .idCard {
                    DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                }
                DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)
                
            default:
                TextField("Your Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField(getDetailLabel(), text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
            }
        }
    }

    // MARK: - PHOTO UPLOAD COMPONENTS
    @ViewBuilder
    private var documentPhotoUploadDivider: some View {
        HStack {
            VStack { Divider() }
            Text("OR")
                .font(.caption.bold())
                .foregroundColor(.gray)
            VStack { Divider() }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var documentPhotoUploadArea: some View {
        if let imageData = documentImage, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
                .frame(maxHeight: 200)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.3)) { documentImage = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
        }
        
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Spacer()
                Label(documentImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle")
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
        .listRowBackground(
            Capsule()
                .foregroundColor(Color(uiColor: .secondarySystemGroupedBackground))
                .padding(.vertical, 4)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getDetailLabel() -> String {
        switch type {
        case .studentID:
            return "Student number"
        case .visa:
            return "Confirmation Code"
        default:
            return "Booking Number"
        }
    }
    
    func saveDocument() {
        var finalTitle = title
        var finalSubtitle = subtitle
        var finalHolder = holderName
        var finalDetail = detailValue
        var finalAirline = ""
        
        switch type {
        case .medicalAlert:
            let bloodTypePart = "TYPE: \(selectedBloodType)"
            let allergyPart = holderName.isEmpty ? "" : ", ALLERGIES: \(holderName)"
            finalHolder = bloodTypePart + allergyPart
            finalTitle = "Medical Alert"
            finalSubtitle = "BLOOD / ALLERGY"
            
        case .vaccineRecord:
            finalTitle = "Vaccination"
            finalSubtitle = selectedVaccine.uppercased()
            
        case .boardingPass:
            finalAirline = selectedAirline
            
        case .insurance:
            finalSubtitle = subtitle.uppercased() + " INSURANCE"
            
        case .driversLicense:
            finalSubtitle = "DRIVER LICENSE"

        case .birthCertificate, .marriageCertificate:
            finalSubtitle = "OFFICIAL RECORD"
            
        default:
            break
        }
        
        if finalTitle.isEmpty { finalTitle = "New Document" }
        if finalSubtitle.isEmpty { finalSubtitle = type.displayName.uppercased() }
        if finalHolder.isEmpty { finalHolder = "CARD HOLDER" }
        
        let newDoc = TravelDocument(
            id: existingID ?? UUID(),
            type: type,
            title: finalTitle,
            subtitle: finalSubtitle,
            holderName: finalHolder,
            detailValue: finalDetail,
            origin: type == .boardingPass ? origin : nil,
            nationality: (type == .passport || type == .driversLicense) ? nationality : nil,
            birthDate: (type == .passport || type == .driversLicense || type == .idCard) ? birthDate : nil,
            issueDate: (type == .passport || type == .insurance || type == .driversLicense) ? issueDate : nil,
            expiryDate: (type == .passport || type == .insurance || type == .driversLicense || type == .visa || type == .studentID || type == .idCard) ? expiryDate : nil,
            gate: type == .boardingPass ? gate : nil,
            seat: type == .boardingPass ? seat : nil,
            flightClass: type == .boardingPass ? flightClass : nil,
            flightDate: type == .boardingPass ? flightDate : nil,
            boardingTime: type == .boardingPass ? boardingTime : nil,
            groupNumber: type == .insurance ? groupNumber : nil,
            emergencyPhoneNumber: type == .insurance ? emergencyPhoneNumber : nil,
            address: type == .driversLicense ? address : nil,
            licenseClass: type == .driversLicense ? licenseClass : nil,
            restrictions: type == .driversLicense ? restrictions : nil,
            endorsements: type == .driversLicense ? endorsements : nil,
            height: type == .driversLicense ? height : nil,
            eyeColor: type == .driversLicense ? eyeColor : nil,
            documentImageData: (type == .driversLicense || type == .passport || type == .idCard || type == .studentID) ? documentImage : nil,
            primaryColor: getColor(for: type),
            secondaryColor: .white,
            iconName: getIcon(for: type),
            airline: finalAirline,
            isActive: true
        )
        
        onSave(newDoc)
    }
    
    func getColor(for type: TravelDocument.DocumentType) -> Color {
        switch type {
        case .driversLicense: return Color(red: 0.2, green: 0.3, blue: 0.45)
        case .studentID: return Color(red: 0.5, green: 0.1, blue: 0.1)
        case .prescription: return Color(red: 0.0, green: 0.6, blue: 0.45)
        case .vaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7)
        case .medicalAlert: return Color(red: 0.85, green: 0.2, blue: 0.2)
        case .birthCertificate: return Color(red: 0.4, green: 0.3, blue: 0.2)
        case .marriageCertificate: return Color(red: 0.7, green: 0.5, blue: 0.2)
        case .passport: return Color(red: 0.05, green: 0.05, blue: 0.25)
        case .boardingPass: return Color(red: 1.0, green: 0.31, blue: 0.0)
        case .visa: return Color(red: 0.85, green: 0.2, blue: 0.3)
        case .insurance: return Color(red: 0.0, green: 0.5, blue: 0.5)
        case .idCard: return Color(red: 0.45, green: 0.2, blue: 0.6)
        }
    }
    
    func getIcon(for type: TravelDocument.DocumentType) -> String {
        switch type {
        case .driversLicense: return "car.fill"
        case .studentID: return "graduationcap.fill"
        case .prescription: return "pills.fill"
        case .vaccineRecord: return "syringe.fill"
        case .medicalAlert: return "staroflife.fill"
        case .birthCertificate: return "stroller.fill"
        case .marriageCertificate: return "figure.and.child.holdinghands"
        case .passport: return "globe"
        case .boardingPass: return "airplane"
        case .visa: return "checkmark.seal"
        case .insurance: return "cross.case.fill"
        case .idCard: return "person.text.rectangle.fill"
        }
    }
}

/// A reusable view for airport text fields with autocomplete suggestions.
fileprivate struct AirportSelectionField: View {
    let title: String
    @Binding var selection: String
    let airports: [(code: String, name: String)]
    let onSelect: (String, String) -> Void

    var body: some View {
        TextField(title, text: $selection)
            .textInputAutocapitalization(.words)
        if !airports.isEmpty {
            ForEach(airports, id: \.code) { airport in
                Button(action: {
                    onSelect(airport.name, airport.code)
                }) {
                    HStack {
                        Text(airport.name).foregroundColor(.primary)
                        Spacer()
                        Text(airport.code)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

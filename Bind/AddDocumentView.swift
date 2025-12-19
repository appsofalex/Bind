import SwiftUI

// MARK: - NEW: ADD DOCUMENT VIEW & FORM
struct AddDocumentView: View {
    let type: TravelDocument.DocumentType
    let onAdd: (TravelDocument) -> Void
    let existingID: UUID? // Stores ID if we are editing
    
    @Environment(\.dismiss) var dismiss
    
    // Form Fields
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var holderName: String = ""
    @State private var detailValue: String = ""
    
    // Specific Dropdowns
    @State private var selectedBloodType = "A+"
    @State private var selectedAllergy = "None"
    @State private var selectedVaccine = "COVID-19"
    @State private var selectedUniversity = "State Univ"
    @State private var selectedAirline = "British Airways"
    
    // PASSPORT SPECIFIC FIELDS
    @State private var nationality: String = ""
    @State private var birthDate: Date = Date()
    @State private var issueDate: Date = Date()
    @State private var expiryDate: Date = Date()
    
    // BOARDING PASS SPECIFIC FIELDS
    @State private var origin: String = "" // NEW
    @State private var gate: String = ""
    @State private var seat: String = ""
    @State private var flightClass: String = "Economy"
    @State private var flightDate: Date = Date()
    @State private var boardingTime: Date = Date()
    
    let bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let vaccines = ["COVID-19", "Influenza", "Yellow Fever", "Tetanus", "Hepatitis B", "Measles"]
    let visaTypes = ["Tourist Visa", "Business Visa", "Student Visa", "Work Visa", "Transit Visa", "Investor Visa", "Spouse Visa", "Visitor Visa"]
    
    // MARK: - NEW: COUNTRY DATA
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
        "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria",
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
    
    // MARK: - NEW: AIRPORT DATA
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
    
    // MARK: - NEW: AIRPORT FILTER LOGIC
    func filteredAirports(for query: String) -> [(code: String, name: String)] {
        if query.isEmpty { return [] }
        
        // 1. Find matches
        let matches = airports.filter { code, name in
            code.localizedCaseInsensitiveContains(query) || name.localizedCaseInsensitiveContains(query)
        }
        
        // 2. Hide suggestions if the user has already selected a valid full entry
        if matches.contains(where: { "\( $0.1 ) (\( $0.0 ))" == query }) {
            return []
        }
        
        // 3. Sort alphabetically by name
        return matches.sorted { $0.1 < $1.1 }.map { (code: $0.0, name: $0.1) }
    }
    
    // Initialize default values based on type OR existing document
    init(type: TravelDocument.DocumentType? = nil,
         document: TravelDocument? = nil,
         onAdd: @escaping (TravelDocument) -> Void) {
        
        self.onAdd = onAdd
        
        if let doc = document {
            // EDIT MODE
            self.type = doc.type
            self.existingID = doc.id
            
            _title = State(initialValue: doc.title)
            _subtitle = State(initialValue: doc.subtitle)
            _holderName = State(initialValue: doc.holderName)
            _detailValue = State(initialValue: doc.detailValue)
            _nationality = State(initialValue: doc.nationality ?? "")
            
            if let dob = doc.birthDate { _birthDate = State(initialValue: dob) }
            if let iss = doc.issueDate { _issueDate = State(initialValue: iss) }
            if let exp = doc.expiryDate { _expiryDate = State(initialValue: exp) }
            
            // Try to pre-fill airline if it exists in our segments (mostly visual)
            if !doc.airline.isEmpty {
                _selectedAirline = State(initialValue: doc.airline)
            }
            
            // Pre-fill Boarding Pass specifics
            _origin = State(initialValue: doc.origin ?? "")
            _gate = State(initialValue: doc.gate ?? "")
            _seat = State(initialValue: doc.seat ?? "")
            _flightClass = State(initialValue: doc.flightClass ?? "Economy")
            if let fd = doc.flightDate { _flightDate = State(initialValue: fd) }
            if let bt = doc.boardingTime { _boardingTime = State(initialValue: bt) }
            
        } else {
            // ADD MODE
            let targetType = type ?? .passport
            self.type = targetType
            self.existingID = nil
            
            // Defaults
            switch targetType {
            case .passport:
                // Default country
                _title = State(initialValue: "United Kingdom")
                _nationality = State(initialValue: "United Kingdom")
            case .visa:
                _title = State(initialValue: "United States")
                _subtitle = State(initialValue: "Tourist Visa")
            case .driversLicense:
                _title = State(initialValue: "California")
                _subtitle = State(initialValue: "DRIVER LICENSE")
            case .studentID:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "Student ID")
            case .prescription:
                _title = State(initialValue: "Pharmacy")
                _subtitle = State(initialValue: "RX PRESCRIPTION")
            case .vaccineRecord:
                _title = State(initialValue: "CDC / NHS")
                _subtitle = State(initialValue: "VACCINATION")
            case .medicalAlert:
                _title = State(initialValue: "Medical Alert")
                _subtitle = State(initialValue: "EMERGENCY INFO")
            default:
                break
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    // Context-aware fields
                    if type == .medicalAlert {
                        Picker("Blood Type", selection: $selectedBloodType) {
                            ForEach(bloodTypes, id: \.self) { Text($0) }
                        }
                        TextField("Allergies", text: $holderName) // Using holderName for Allergy list
                            .textInputAutocapitalization(.sentences)
                            .overlay(
                                Text("e.g. Peanuts, Penicillin").foregroundColor(.gray.opacity(0.5)).allowsHitTesting(false).opacity(holderName.isEmpty ? 1 : 0),
                                alignment: .leading
                            )
                    } else if type == .vaccineRecord {
                         Picker("Vaccine Type", selection: $selectedVaccine) {
                             ForEach(vaccines, id: \.self) { Text($0) }
                         }
                         TextField("Date / Dose", text: $detailValue)
                    } else if type == .boardingPass {
                         Picker("Airline", selection: $selectedAirline) {
                             ForEach(airlineSegments, id: \.country) { segment in
                                 Section(header: Text(segment.country)) {
                                     ForEach(segment.airlines, id: \.self) { airline in
                                         Text(airline).tag(airline)
                                     }
                                 }
                             }
                         }
                         
                         // MARK: - NEW: AUTOCOMPLETE AIRPORT FIELDS
                        TextField("Origin (Type code or city)", text: $origin)
                            .textInputAutocapitalization(.words)
                        
                        // Suggestions for Origin
                        if !filteredAirports(for: origin).isEmpty {
                            ForEach(filteredAirports(for: origin), id: \.code) { airport in
                                Button(action: {
                                    origin = "\(airport.name) (\(airport.code))"
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
                        
                         TextField("Destination (Type code or city)", text: $title)
                             .textInputAutocapitalization(.words)
                         
                         // Suggestions for Destination
                        if !filteredAirports(for: title).isEmpty {
                             ForEach(filteredAirports(for: title), id: \.code) { airport in
                                 Button(action: {
                                     title = "\(airport.name) (\(airport.code))"
                                 }) {
                                     HStack {
                                         Text(airport.name)
                                             .foregroundColor(.primary)
                                         Spacer()
                                         Text(airport.code)
                                             .font(.system(.subheadline, design: .monospaced))
                                             .fontWeight(.bold)
                                             .foregroundColor(.gray)
                                     }
                                 }
                             }
                         }
                        
                        // NEW BOARDING PASS DETAILS
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
                        
                    } else if type == .passport {
                        // MARK: - NEW: PASSPORT COUNTRY PICKER
                        Picker("Country", selection: $title) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        // Auto-update Nationality when Country changes
                        .onChange(of: title) { newValue in
                            nationality = newValue
                        }
                        // No subtitle field for passport
                    } else if type == .visa {
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
                    } else {
                        TextField(type == .studentID ? "University name" : "Title (e.g. Country, State)", text: $title)
                            .textInputAutocapitalization(.words)
                        TextField("Subtitle (e.g. License Type)", text: $subtitle)
                            .textInputAutocapitalization(type == .studentID ? .sentences : .characters)
                    }
                }
                
                Section(header: Text("Personal Info")) {
                    if type == .medicalAlert {
                        // Already handled allergies above, use this for Emergency Contact
                        TextField("Emergency Contact", text: $detailValue)
                            .textInputAutocapitalization(.words)
                    } else if type == .passport {
                        // MARK: - SPECIFIC PASSPORT FIELDS
                        TextField("Full Name", text: $holderName)
                            .textInputAutocapitalization(.words)
                        TextField("Passport Number", text: $detailValue)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: detailValue) { newValue in
                                detailValue = newValue.uppercased()
                            }
                        TextField("Nationality", text: $nationality) // Auto-filled but editable
                            .textInputAutocapitalization(.words)
                        
                        DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                        DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)
                    } else if type == .boardingPass {
                         TextField("Passenger Name", text: $holderName)
                             .textInputAutocapitalization(.words)
                         TextField("Flight Number", text: $detailValue)
                             .textInputAutocapitalization(.characters)
                             .onChange(of: detailValue) { newValue in
                                 detailValue = newValue.uppercased()
                             }
                    } else {
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
            .navigationTitle(existingID != nil ? "Edit \(type.displayName)" : "Add \(type.displayName)")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(existingID != nil ? "Save" : "Add") {
                    saveDocument()
                    dismiss()
                }
            )
        }
    }
    
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
        // Construct the document based on type-specific logic
        
        var finalTitle = title
        var finalSubtitle = subtitle
        var finalHolder = holderName
        var finalDetail = detailValue
        var finalAirline = ""
        
        // Custom Construction Logic
        switch type {
        case .medicalAlert:
            finalTitle = "Medical Alert"
            finalSubtitle = "BLOOD / ALLERGY"
            finalHolder = "TYPE: \(selectedBloodType)" // Store Blood Type in Holder slot
            // finalDetail holds Emergency Contact or Allergies
            
        case .vaccineRecord:
            finalTitle = "Vaccination"
            finalSubtitle = selectedVaccine.uppercased()
            // finalHolder is Name
            // finalDetail is Date
            
        case .boardingPass:
            finalAirline = selectedAirline
            
        default:
            break
        }
        
        // Defaults if empty
        if finalTitle.isEmpty { finalTitle = "New Document" }
        // NEW: Ensure subtitle defaults to the document type name if not set manually
        if finalSubtitle.isEmpty { finalSubtitle = type.displayName.uppercased() }
        if finalHolder.isEmpty { finalHolder = "CARD HOLDER" }
        
        let newDoc = TravelDocument(
            id: existingID ?? UUID(), // Preserve ID if editing
            type: type,
            title: finalTitle,
            subtitle: finalSubtitle,
            holderName: finalHolder,
            detailValue: finalDetail,
            origin: type == .boardingPass ? origin : nil,
            nationality: type == .passport ? nationality : nil,
            birthDate: type == .passport ? birthDate : nil,
            issueDate: type == .passport ? issueDate : nil,
            expiryDate: type == .passport ? expiryDate : nil,
            // Boarding Pass fields
            gate: type == .boardingPass ? gate : nil,
            seat: type == .boardingPass ? seat : nil,
            flightClass: type == .boardingPass ? flightClass : nil,
            flightDate: type == .boardingPass ? flightDate : nil,
            boardingTime: type == .boardingPass ? boardingTime : nil,
            
            primaryColor: getColor(for: type),
            secondaryColor: .white,
            iconName: getIcon(for: type),
            airline: finalAirline
        )
        
        onAdd(newDoc)
    }
    
    func getColor(for type: TravelDocument.DocumentType) -> Color {
        switch type {
        case .driversLicense: return Color(red: 0.2, green: 0.3, blue: 0.45) // Slate Blue
        case .studentID: return Color(red: 0.5, green: 0.1, blue: 0.1) // Maroon
        case .prescription: return Color(red: 0.0, green: 0.6, blue: 0.45) // Pharmacy Teal
        case .vaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7) // Health Blue
        case .medicalAlert: return Color(red: 0.85, green: 0.2, blue: 0.2) // Alert Red
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
        case .passport: return "globe"
        case .boardingPass: return "airplane"
        case .visa: return "checkmark.seal"
        case .insurance: return "cross.fill"
        case .idCard: return "person.text.rectangle.fill"
        }
    }
}

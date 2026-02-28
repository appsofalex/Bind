import SwiftUI
import PhotosUI
import VisionKit
import Vision

/// Rotate image 90° clockwise so certificate photos display horizontally on the card.
fileprivate extension UIImage {
    func rotated90DegreesClockwise() -> UIImage {
        let newSize = CGSize(width: size.height, height: size.width)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return self }
        ctx.translateBy(x: size.height, y: 0)
        ctx.rotate(by: .pi / 2)
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

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
    let existingCreatedAt: Date? // Preserve creation date when editing (for stack chronological order)
    let existingStackOrderIndex: Int? // Preserve stack order when editing (newest at front)
    let prefilledTitle: String? // Optional prefill title
    let initialScanResult: ScanResult? // Pre-filled from Quick Scan

    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Form Fields
    @State private var title: String
    @State private var subtitle: String
    @State private var holderName: String
    @State private var detailValue: String
    
    // Specific Dropdowns
    @State private var selectedBloodType: String
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
    @State private var emergencyContactName: String
    @State private var emergencyContactEmail: String
    @State private var allergies: String
    
    // DRIVER'S LICENSE SPECIFIC FIELDS
    @State private var address: String
    @State private var licenseClass: String
    @State private var restrictions: String
    @State private var endorsements: String
    @State private var height: String
    @State private var eyeColor: String
    @State private var documentImage: Data?
    
    // CAR RENTAL SPECIFIC FIELDS
    @State private var selectedCarBrand: String = ""
    @State private var carModel: String = ""
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var pickupDate: Date = Date()
    @State private var dropoffDate: Date = Date().addingTimeInterval(3600 * 24 * 3) // 3 days later
    
    // REWARDS CARD SPECIFIC
    @State private var selectedRewardType: String = "Coffee"
    @State private var selectedRewardBrand: String = ""
    @State private var selectedAirlineTier: String = "Silver"
    
    // PET SPECIFIC FIELDS
    @State private var petName: String = ""
    @State private var petSpecies: String = "Dog"
    @State private var petBreed: String = ""
    @State private var petMicrochipNumber: String = ""
    @State private var vetName: String = ""
    
    // PRESCRIPTION SPECIFIC FIELDS
    @State private var frequency: String = "Once daily"
    @State private var route: String = "Oral"
    @State private var doctorName: String = ""
    @State private var pharmacyName: String = ""
    @State private var refills: String = "0"
    
    // VACCINE SPECIFIC FIELDS
    @State private var dose: String = ""
    @State private var manufacturer: String = ""
    
    // HOTEL KEY SPECIFIC FIELDS
    @State private var selectedHotelBrand: String = ""
    @State private var hotelAddress: String = ""
    @State private var hotelPhoneNumber: String = ""
    @State private var reservationNumber: String = ""
    @State private var wifiPassword: String = ""
    @State private var selectedRoomType: String = "Standard"
    @State private var loyaltyNumber: String = ""
    
    // EVENT SPECIFIC FIELDS
    @State private var selectedEventType: String = "Concert"
    @State private var venueName: String = ""
    @State private var venueLocation: String = ""
    @State private var section: String = ""
    @State private var row: String = ""
    @State private var eventDate: Date = Date()
    @State private var ticketType: String = "General Admission"
    
    // VISA SPECIFIC FIELDS
    @State private var visaNumber: String = ""
    @State private var passportNumber: String = ""
    @State private var entries: String = "Single"
    @State private var issuingAuthority: String = ""
    @State private var placeOfIssue: String = ""
    @State private var visaRemarks: String = ""
    
    // BIRTH CERTIFICATE SPECIFIC FIELDS
    @State private var placeOfBirth: String = ""
    @State private var registrationDistrict: String = ""
    @State private var fatherName: String = ""
    @State private var motherName: String = ""
    @State private var selectedGender: String = "Male"

    // MARRIAGE CERTIFICATE SPECIFIC FIELDS
    @State private var spouseName: String = ""
    @State private var marriageDate: Date = Date()
    @State private var marriagePlace: String = ""
    @State private var officiantName: String = ""
    @State private var witnesses: String = ""
    
    // PRO: Custom card colours (used when subscriptionManager.isPro)
    @State private var customPrimaryColor: Color = .blue
    @State private var customSecondaryColor: Color = .white
    // PRO: Custom card icon (used when subscriptionManager.isPro)
    @State private var selectedIconName: String = "doc.fill"
    // PRO: Remember icon/colour for future cards of this type
    @State private var rememberIconForFuture: Bool = false
    @State private var rememberColorForFuture: Bool = false
    
    // Image Picker & Cropper State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageToCrop: CroppableImage?
    
    // SCANNER STATE
    @State private var showScanner = false
    @State private var scannedData: ScanResult?
    @State private var showScannerUnavailableAlert = false
    @State private var hasAppliedInitialScan = false

    // BARCODE FROM SCREENSHOT
    @State private var barcodePayload: String?
    @State private var barcodeScreenshotItem: PhotosPickerItem?
    @State private var showBarcodeNotFoundAlert = false
    @State private var isExtractingBarcode = false
    
    // CAMERA STATE (Take Photo)
    @State private var showCamera = false
    
    // MARK: - DATA COLLECTIONS
    let bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let vaccines = [
        "COVID-19", "Influenza", "Tetanus", "Hepatitis A", "Hepatitis B", "MMR (Measles, Mumps, Rubella)",
        "HPV", "Chickenpox", "Shingles", "Pneumococcal", "Meningococcal", "Typhoid", "Yellow Fever", "Rabies",
        "Polio", "DTP (Diphtheria, Tetanus, Pertussis)"
    ]
    
    let vaccineManufacturers = [
        "Pfizer (Comirnaty)", "Moderna (Spikevax)", "AstraZeneca (Vaxzevria)", "Janssen (J&J)", "Novavax (Nuvaxovid)",
        "Sinovac (CoronaVac)", "Sinopharm (BIBP)", "CanSino (Convidecia)", "Bharat Biotech (Covaxin)",
        "Serum Institute of India (Covishield)", "Sputnik V (Gam-COVID-Vac)", "GSK (GlaxoSmithKline)",
        "Sanofi Pasteur", "Merck Sharp & Dohme (MSD)", "Seqirus", "Valneva", "Bavarian Nordic", "Dynavax",
        "Emergent BioSolutions", "Biological E. Limited", "Bio Farma", "Fiocruz", "Cansino Biologics"
    ]
    
    let doseOptions = [
        "1st Dose", "2nd Dose", "3rd Dose", "4th Dose", "Booster", "Booster 1", "Booster 2", "Annual", "Single Dose"
    ]
    
    let genderOptions = ["Male", "Female", "Other"]
    
    let visaTypes = ["Tourist Visa", "Business Visa", "Student Visa", "Work Visa", "Transit Visa", "Investor Visa", "Spouse Visa", "Visitor Visa"]
    let insuranceTypes = ["Travel", "Health", "Auto", "Dental", "Life", "Home & Contents"]
    
    // PRESCRIPTION DATA
    let prescriptionFrequencies = [
        "Once daily", "Twice daily", "Three times daily", "Four times daily",
        "Every 4 hours", "Every 6 hours", "Every 8 hours", "Every 12 hours",
        "As needed (PRN)", "Before bed", "In the morning", "With food", "Weekly"
    ]
    
    let prescriptionRoutes = [
        "Oral", "Topical", "Inhalation", "Injection", "Ophthalmic (Eye)",
        "Otic (Ear)", "Nasal", "Sublingual", "Rectal"
    ]
    
    let refillOptions = ["0", "1", "2", "3", "4", "5", "6", "11", "12", "PRN"]
    
    // Static list for UK Driver's License classes
    let licenseClasses = ["Category B (Car)", "Category A (Motorcycle)", "Category C (Large Goods)", "Category D (Bus)", "Provisional"]

    // REWARDS DATA
    let rewardTypes = ["Coffee", "Airline", "Supermarket"]
    let coffeeShops = ["Starbucks", "Pret A Manger", "Costa Coffee", "Philz Coffee", "Caffè Nero", "Tim Hortons", "Dunkin'", "McCafé"]
    let supermarkets = ["Waitrose", "Tesco", "Sainsbury's", "M&S Food", "Co-op", "Asda", "Morrisons", "Lidl", "Aldi", "Waitrose & Partners"]

    let carRentalCompanies = [
        "Hertz", "Avis", "Europcar", "Sixt", "Enterprise", "Budget", "National", "Alamo",
        "Dollar", "Thrifty", "Goldcar", "Centauro", "Virtuo", "Keddy", "Record Go", "Locauto"
    ]
    
    let petSpeciesList = ["Dog", "Cat", "Bird", "Rabbit", "Hamster", "Reptile", "Other"]

    let hotelBrands = [
        "Marriott", "Hilton", "Hyatt", "IHG (InterContinental)", "Accor", "Wyndham", "Choice Hotels", "Best Western",
        "Radisson", "Four Seasons", "Ritz-Carlton", "St. Regis", "Waldorf Astoria", "W Hotels", "Westin", "Sheraton",
        "Holiday Inn", "Premier Inn", "Travelodge", "Ibis", "Mercure", "Novotel", "Shangri-La", "Mandarin Oriental",
        "Fairmont", "Rosewood", "Aman", "Belmond", "Langham", "Pan Pacific", "Kimpton", "Omni Hotels",
        "Loews", "MGM Resorts", "Caesars", "Wyndham Garden", "Ramada", "Days Inn", "Super 8", "Motel 6",
        "CitizenM", "Mama Shelter", "Moxy", "Yotel", "Standard Hotels"
    ]
    
    let roomTypes = ["Standard", "Deluxe", "Suite", "Executive", "Family", "Studio", "Penthouse", "Accessible", "Twin", "King", "Queen", "Club"]

    let eventTypes = ["Concert", "Sports", "Theatre", "Cinema", "Conference", "Festival", "Museum", "Other"]
    let ticketTypeOptions = ["General Admission", "VIP", "Standard", "Early Bird", "Student", "Child", "Senior", "Member"]

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
        ("SJC", "San Jose International"),
        ("SEA", "Seattle-Tacoma International"),
        ("EWR", "Newark Liberty International"),
        ("IAD", "Washington Dulles"),
        ("SJU", "San Juan Luis Muñoz Marín"),
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
        ("BOM", "Mumbai International"),
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
        ("MRS", "Marseille Provence"),
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
        return [.passport, .driversLicense, .studentID, .idCard, .nationalInsurance, .birthCertificate, .marriageCertificate, .rewardsCard, .carRental, .petPassport, .petID, .petInsurance, .petVaccineRecord, .visa, .prescription, .vaccineRecord, .medicalAlert, .insurance].contains(type)
    }
    
    // Initialize default values based on type OR existing document
    init(type: TravelDocument.DocumentType? = nil,
         document: TravelDocument? = nil,
         prefilledTitle: String? = nil,
         initialScanResult: ScanResult? = nil,
         onSave: @escaping (TravelDocument) -> Void) {
        
        self.onSave = onSave
        self.prefilledTitle = prefilledTitle
        self.initialScanResult = initialScanResult
        
        // Initialize all @State properties
        _title = State(initialValue: "")
        _subtitle = State(initialValue: "")
        _holderName = State(initialValue: "")
        _detailValue = State(initialValue: "")
        _selectedBloodType = State(initialValue: "A+")
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
        _emergencyContactName = State(initialValue: "")
        _emergencyContactEmail = State(initialValue: "")
        _allergies = State(initialValue: "")
        _address = State(initialValue: "")
        _licenseClass = State(initialValue: "")
        _restrictions = State(initialValue: "")
        _endorsements = State(initialValue: "")
        _height = State(initialValue: "")
        _eyeColor = State(initialValue: "")
        _documentImage = State(initialValue: nil)
        
        _petName = State(initialValue: "")
        _petSpecies = State(initialValue: "Dog")
        _petBreed = State(initialValue: "")
        _petMicrochipNumber = State(initialValue: "")
        _vetName = State(initialValue: "")
        
        _frequency = State(initialValue: "Once daily")
        _route = State(initialValue: "Oral")
        _doctorName = State(initialValue: "")
        _pharmacyName = State(initialValue: "")
        _refills = State(initialValue: "0")
        
        _dose = State(initialValue: "")
        _manufacturer = State(initialValue: "")
        
        _selectedHotelBrand = State(initialValue: "")
        _hotelAddress = State(initialValue: "")
        _hotelPhoneNumber = State(initialValue: "")
        _reservationNumber = State(initialValue: "")
        _wifiPassword = State(initialValue: "")
        _selectedRoomType = State(initialValue: "Standard")
        _loyaltyNumber = State(initialValue: "")
        
        _selectedEventType = State(initialValue: "Concert")
        _venueName = State(initialValue: "")
        _venueLocation = State(initialValue: "")
        _section = State(initialValue: "")
        _row = State(initialValue: "")
        _eventDate = State(initialValue: Date())
        _ticketType = State(initialValue: "General Admission")
        
        _visaNumber = State(initialValue: "")
        _passportNumber = State(initialValue: "")
        _entries = State(initialValue: "Single")
        _issuingAuthority = State(initialValue: "")
        _placeOfIssue = State(initialValue: "")
        _visaRemarks = State(initialValue: "")
        
        _placeOfBirth = State(initialValue: "")
        _registrationDistrict = State(initialValue: "")
        _fatherName = State(initialValue: "")
        _motherName = State(initialValue: "")
        _selectedGender = State(initialValue: "Male")
        
        _spouseName = State(initialValue: "")
        _marriageDate = State(initialValue: Date())
        _marriagePlace = State(initialValue: "")
        _officiantName = State(initialValue: "")
        _witnesses = State(initialValue: "")
        
        if let doc = document {
            // EDIT MODE
            self.type = doc.type
            self.existingID = doc.id
            self.existingCreatedAt = doc.createdAt
            self.existingStackOrderIndex = doc.stackOrderIndex
            
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
            _emergencyContactName = State(initialValue: doc.emergencyContactName ?? "")
            _emergencyContactEmail = State(initialValue: doc.emergencyContactEmail ?? "")
            _allergies = State(initialValue: doc.allergies ?? "")
            
            _address = State(initialValue: doc.address ?? "")
            _licenseClass = State(initialValue: doc.licenseClass ?? "")
            _restrictions = State(initialValue: doc.restrictions ?? "")
            _endorsements = State(initialValue: doc.endorsements ?? "")
            _height = State(initialValue: doc.height ?? "")
            _eyeColor = State(initialValue: doc.eyeColor ?? "")
            _documentImage = State(initialValue: doc.documentImageData)
            
            _dose = State(initialValue: doc.dose ?? "")
            _manufacturer = State(initialValue: doc.manufacturer ?? "")
            
            _visaNumber = State(initialValue: doc.visaNumber ?? "")
            _passportNumber = State(initialValue: doc.passportNumber ?? "")
            _entries = State(initialValue: doc.entries ?? "Single")
            _issuingAuthority = State(initialValue: doc.issuingAuthority ?? "")
            _placeOfIssue = State(initialValue: doc.placeOfIssue ?? "")
            _visaRemarks = State(initialValue: doc.visaRemarks ?? "")
            
            _placeOfBirth = State(initialValue: doc.placeOfBirth ?? "")
            // Fallback for older documents where registration district was in title
            if doc.type == .birthCertificate && (doc.registrationDistrict == nil || doc.registrationDistrict!.isEmpty) && doc.title != "Birth Certificate" {
                 _registrationDistrict = State(initialValue: doc.title)
            } else {
                 _registrationDistrict = State(initialValue: doc.registrationDistrict ?? "")
            }
            _fatherName = State(initialValue: doc.fatherName ?? "")
            _motherName = State(initialValue: doc.motherName ?? "")
            _selectedGender = State(initialValue: doc.gender ?? "Male")
            
            _spouseName = State(initialValue: doc.spouseName ?? "")
            if let md = doc.marriageDate { _marriageDate = State(initialValue: md) }
            _marriagePlace = State(initialValue: doc.marriagePlace ?? "")
            _officiantName = State(initialValue: doc.officiantName ?? "")
            _witnesses = State(initialValue: doc.witnesses ?? "")
            
            _carModel = State(initialValue: doc.carModel ?? "")
            _pickupLocation = State(initialValue: doc.pickupLocation ?? "")
            _dropoffLocation = State(initialValue: doc.dropoffLocation ?? "")
            if let pd = doc.pickupDate { _pickupDate = State(initialValue: pd) }
            if let dd = doc.dropoffDate { _dropoffDate = State(initialValue: dd) }
            
            _hotelAddress = State(initialValue: doc.hotelAddress ?? "")
            _hotelPhoneNumber = State(initialValue: doc.hotelPhoneNumber ?? "")
            _reservationNumber = State(initialValue: doc.reservationNumber ?? "")
            _wifiPassword = State(initialValue: doc.wifiPassword ?? "")
            _selectedRoomType = State(initialValue: doc.roomType ?? "Standard")
            _loyaltyNumber = State(initialValue: doc.loyaltyNumber ?? "")
            
            _selectedEventType = State(initialValue: doc.eventType ?? "Concert")
            _venueName = State(initialValue: doc.venueName ?? "")
            _venueLocation = State(initialValue: doc.venueLocation ?? "")
            _section = State(initialValue: doc.section ?? "")
            _barcodePayload = State(initialValue: doc.barcodePayload)
            _row = State(initialValue: doc.row ?? "")
            if let ed = doc.eventDate { _eventDate = State(initialValue: ed) }
            _ticketType = State(initialValue: doc.ticketType ?? "General Admission")
            
            if doc.type == .carRental {
                _selectedCarBrand = State(initialValue: doc.title)
            } else if doc.type == .hotelKeyCard {
                _selectedHotelBrand = State(initialValue: doc.title)
            }
            
            _petName = State(initialValue: doc.petName ?? "")
            _petSpecies = State(initialValue: doc.petSpecies ?? "Dog")
            _petBreed = State(initialValue: doc.petBreed ?? "")
            _petMicrochipNumber = State(initialValue: doc.petMicrochipNumber ?? "")
            _vetName = State(initialValue: doc.vetName ?? "")
            
            _frequency = State(initialValue: doc.frequency ?? "Once daily")
            _route = State(initialValue: doc.route ?? "Oral")
            _doctorName = State(initialValue: doc.doctorName ?? "")
            _pharmacyName = State(initialValue: doc.pharmacyName ?? "")
            _refills = State(initialValue: doc.refills ?? "0")
            
            if doc.type == .medicalAlert {
                if let bloodTypeRange = doc.holderName.range(of: "TYPE: ") {
                    _selectedBloodType = State(initialValue: String(doc.holderName[bloodTypeRange.upperBound...]))
                }
            } else if doc.type == .vaccineRecord {
                // IMPORTANT: Subtitle is "VACCINE - DOSE", so we want just "VACCINE"
                // e.g. "COVID-19 - 1ST DOSE" -> "COVID-19"
                if let vaccineName = doc.subtitle.components(separatedBy: " - ").first {
                    // Try to match the case-insensitive version from the list to get the exact string back
                    if let match = vaccines.first(where: { $0.caseInsensitiveCompare(vaccineName) == .orderedSame }) {
                        _selectedVaccine = State(initialValue: match)
                    } else {
                        // Fallback: Just use what we parsed, properly capitalized
                        _selectedVaccine = State(initialValue: vaccineName.capitalized)
                    }
                } else {
                    _selectedVaccine = State(initialValue: doc.subtitle.capitalized)
                }
            } else if doc.type == .rewardsCard {
                _selectedRewardBrand = State(initialValue: doc.title)
                _selectedAirlineTier = State(initialValue: doc.airlineTier ?? "Silver")
                // Try to guess the type based on the brand or subtitle
                if doc.subtitle.localizedCaseInsensitiveContains("COFFEE") {
                    _selectedRewardType = State(initialValue: "Coffee")
                } else if doc.subtitle.localizedCaseInsensitiveContains("AIRLINE") || doc.subtitle.localizedCaseInsensitiveContains("FLYER") {
                    _selectedRewardType = State(initialValue: "Airline")
                } else if doc.subtitle.localizedCaseInsensitiveContains("SUPERMARKET") || doc.subtitle.localizedCaseInsensitiveContains("GROCERY") {
                    _selectedRewardType = State(initialValue: "Supermarket")
                }
            }
            
            _customPrimaryColor = State(initialValue: doc.primaryColor)
            _customSecondaryColor = State(initialValue: doc.secondaryColor)
            _selectedIconName = State(initialValue: doc.iconName)
            _rememberIconForFuture = State(initialValue: UserDefaults.standard.bool(forKey: Self.rememberIconKey(doc.type)))
            _rememberColorForFuture = State(initialValue: UserDefaults.standard.bool(forKey: Self.rememberColorKey(doc.type)))
            
        } else {
            // ADD MODE
            let targetType = type ?? .passport
            self.type = targetType
            self.existingID = nil
            self.existingCreatedAt = nil
            self.existingStackOrderIndex = nil
            
            switch targetType {
            case .passport:
                _title = State(initialValue: "United Kingdom")
                _nationality = State(initialValue: "United Kingdom")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 10))
            case .medicalAlert:
                // Special handling for prefilled titles
                if let prefill = prefilledTitle, !prefill.isEmpty {
                    _title = State(initialValue: prefill)
                    if prefill == "Blood Type" {
                        _subtitle = State(initialValue: "Blood Type")
                        _holderName = State(initialValue: "Type: A+")
                    } else if prefill == "Emergency Contact" {
                        _subtitle = State(initialValue: "Contact")
                    } else {
                        _subtitle = State(initialValue: "Emergency Info")
                    }
                } else {
                    _title = State(initialValue: "Medical Card")
                    _subtitle = State(initialValue: "Emergency Info")
                    _holderName = State(initialValue: "Type: A+")
                }
            case .visa:
                _title = State(initialValue: "United States")
                _subtitle = State(initialValue: "Tourist Visa")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 5))
            case .insurance:
                if let prefill = prefilledTitle, prefill == "NHS Number" {
                    _title = State(initialValue: "NHS")
                    _subtitle = State(initialValue: "NHS Number")
                } else {
                    _subtitle = State(initialValue: "Health")
                }
                _issueDate = State(initialValue: Date())
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60))
            case .driversLicense:
                _title = State(initialValue: "United Kingdom")
                _subtitle = State(initialValue: "Driver License")
                _licenseClass = State(initialValue: "Category B (Car)")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 5))
            case .studentID:
                _subtitle = State(initialValue: "Student ID")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 4))
            case .prescription:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "")
                _frequency = State(initialValue: "Once daily")
                _route = State(initialValue: "Oral")
                _refills = State(initialValue: "0")
            case .vaccineRecord:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "Vaccination")
                _dose = State(initialValue: "1st Dose")
                _manufacturer = State(initialValue: "Pfizer (Comirnaty)")
                _issueDate = State(initialValue: Date())
            case .birthCertificate:
                _title = State(initialValue: "Birth Certificate")
                _subtitle = State(initialValue: "Birth Certificate")
            case .marriageCertificate:
                _title = State(initialValue: "Marriage Certificate")
                _subtitle = State(initialValue: "Marriage Certificate")
            case .rewardsCard:
                _title = State(initialValue: "Rewards Card")
                _subtitle = State(initialValue: "Loyalty")
            case .event:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "Concert")
                _selectedEventType = State(initialValue: "Concert")
                _eventDate = State(initialValue: Date().addingTimeInterval(3600 * 24 * 7)) // 1 week later
            case .carRental:
                _title = State(initialValue: "Car Rental")
                _subtitle = State(initialValue: "Reservation")
            case .hotelKeyCard:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "Guest Access")
            case .idCard:
                // Pre-fill logic for National Insurance
                if let prefill = prefilledTitle, (prefill == "National Insurance" || prefill == "SSN") {
                    _title = State(initialValue: "United Kingdom")
                    _subtitle = State(initialValue: "National Insurance")
                    _nationality = State(initialValue: "United Kingdom")
                } else {
                    _title = State(initialValue: "United Kingdom")
                    _subtitle = State(initialValue: "National ID")
                    _nationality = State(initialValue: "United Kingdom")
                }
                
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 10))
            case .nationalInsurance:
                _title = State(initialValue: "United Kingdom")
                _subtitle = State(initialValue: "NI Number")
                _nationality = State(initialValue: "United Kingdom")
                
            case .petInsurance:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "")
                _issueDate = State(initialValue: Date())
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60))
            case .petVaccineRecord:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "")
            case .petPassport:
                _title = State(initialValue: "United Kingdom")
                _subtitle = State(initialValue: "Pet Passport")
                _expiryDate = State(initialValue: Date().addingTimeInterval(365 * 24 * 60 * 60 * 5))
            case .petID:
                _title = State(initialValue: "")
                _subtitle = State(initialValue: "")
            default:
                break
            }
            
            let remIconOn = UserDefaults.standard.bool(forKey: Self.rememberIconKey(targetType))
            let remColorOn = UserDefaults.standard.bool(forKey: Self.rememberColorKey(targetType))
            let initialIcon = (remIconOn ? UserDefaults.standard.string(forKey: Self.rememberedIconKey(targetType)) : nil) ?? Self.getDefaultIcon(for: targetType)
            let initialColor = (remColorOn ? Self.loadRememberedColor(for: targetType) : nil) ?? Self.defaultPrimaryColor(for: targetType)
            _customPrimaryColor = State(initialValue: initialColor)
            _customSecondaryColor = State(initialValue: .white)
            _selectedIconName = State(initialValue: initialIcon)
            _rememberIconForFuture = State(initialValue: remIconOn)
            _rememberColorForFuture = State(initialValue: remColorOn)
        }
    }
    
    static func rememberIconKey(_ type: TravelDocument.DocumentType) -> String { "pro.rememberIcon.\(type.rawValue)" }
    static func rememberColorKey(_ type: TravelDocument.DocumentType) -> String { "pro.rememberColor.\(type.rawValue)" }
    static func rememberedIconKey(_ type: TravelDocument.DocumentType) -> String { "pro.rememberedIcon.\(type.rawValue)" }
    static func rememberedColorKey(_ type: TravelDocument.DocumentType) -> String { "pro.rememberedColor.\(type.rawValue)" }
    
    static func loadRememberedColor(for type: TravelDocument.DocumentType) -> Color? {
        guard let s = UserDefaults.standard.string(forKey: rememberedColorKey(type)) else { return nil }
        let parts = s.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count >= 3 else { return nil }
        return Color(red: parts[0], green: parts[1], blue: parts[2])
    }
    
    /// Default primary colour per document type (used for new cards and when not Pro).
    private static func defaultPrimaryColor(for type: TravelDocument.DocumentType) -> Color {
        switch type {
        case .driversLicense: return Color(red: 0.2, green: 0.3, blue: 0.45)
        case .studentID: return Color(red: 0.5, green: 0.1, blue: 0.1)
        case .prescription: return Color(red: 0.0, green: 0.6, blue: 0.45)
        case .vaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7)
        case .medicalAlert: return Color(red: 0.85, green: 0.2, blue: 0.2)
        case .birthCertificate: return Color(red: 0.4, green: 0.3, blue: 0.2)
        case .marriageCertificate: return Color(red: 0.7, green: 0.5, blue: 0.2)
        case .rewardsCard: return Color(red: 0.95, green: 0.75, blue: 0.1)
        case .event: return Color(red: 0.0, green: 0.7, blue: 0.8)
        case .carRental: return Color(red: 0.1, green: 0.4, blue: 0.2)
        case .hotelKeyCard: return Color(red: 0.15, green: 0.15, blue: 0.2)
        case .passport: return Color(red: 0.05, green: 0.05, blue: 0.25)
        case .boardingPass: return Color(red: 1.0, green: 0.31, blue: 0.0)
        case .visa: return Color(red: 0.85, green: 0.2, blue: 0.3)
        case .insurance: return Color(red: 0.0, green: 0.5, blue: 0.5)
        case .idCard: return Color(red: 0.45, green: 0.2, blue: 0.6)
        case .nationalInsurance: return Color(red: 0.2, green: 0.6, blue: 0.3)
        case .petInsurance: return Color(red: 0.2, green: 0.6, blue: 0.3)
        case .petVaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7)
        case .petPassport: return Color(red: 0.5, green: 0.1, blue: 0.2)
        case .petID: return Color(red: 0.8, green: 0.4, blue: 0.0)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                quickAddSection
                documentDetailsSection
                if type != .studentID {
                    personalInfoSection
                }
                
                if subscriptionManager.isPro {
                    Section {
                        NavigationLink(destination: CardCustomisationView(
                            customPrimaryColor: $customPrimaryColor,
                            selectedIconName: $selectedIconName,
                            rememberColorForFuture: $rememberColorForFuture,
                            rememberIconForFuture: $rememberIconForFuture,
                            type: type
                        )) {
                            Label("Card Customisation", systemImage: "paintpalette.fill")
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
            .sheet(item: $imageToCrop) { item in
                ImageCropperView(image: item.image) { croppedImage in
                    let imageToSave: UIImage
                    if type == .birthCertificate || type == .marriageCertificate {
                        imageToSave = croppedImage.rotated90DegreesClockwise()
                    } else {
                        imageToSave = croppedImage
                    }
                    documentImage = imageToSave.jpegData(compressionQuality: 0.8)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureWithOverlayView(
                    onImageCaptured: { image in
                        showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            imageToCrop = CroppableImage(image: image)
                        }
                    },
                    onCancel: {
                        showCamera = false
                    }
                )
            }
            // SCANNER SHEET
            .sheet(isPresented: $showScanner) {
                ScannerView(scannedData: $scannedData, recognizedDataTypes: scannerDataTypes, mode: (type == .passport) ? .passport : (type == .boardingPass ? .boardingPass : .barcode))
            }
            .alert("Scanner Unavailable", isPresented: $showScannerUnavailableAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your device does not support scanning documents. This feature requires a camera and is not available on simulators.")
            }
            .onChange(of: scannedData) { _, data in
                if let data = data {
                    handleScanResult(data)
                }
            }
            .onAppear {
                if !hasAppliedInitialScan, let result = initialScanResult {
                    handleScanResult(result)
                    hasAppliedInitialScan = true
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
            .onChange(of: barcodeScreenshotItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    await MainActor.run { isExtractingBarcode = true }
                    defer { Task { @MainActor in isExtractingBarcode = false } }
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let payload = await BarcodeFromImage.extractBarcodePayload(from: image)
                        await MainActor.run {
                            barcodeScreenshotItem = nil
                            if let payload = payload {
                                barcodePayload = payload
                                if detailValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    detailValue = payload
                                }
                            } else {
                                showBarcodeNotFoundAlert = true
                            }
                        }
                    } else {
                        await MainActor.run {
                            barcodeScreenshotItem = nil
                            showBarcodeNotFoundAlert = true
                        }
                    }
                }
            }
            .alert("No Barcode Found", isPresented: $showBarcodeNotFoundAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No barcode or QR code was detected in the image. Try a clearer screenshot or photo.")
            }
        }
    }
    
    // MARK: - View Components
    
    // MARK: - Quick-add Section (Scan, Take Photo, Choose Photo)
    @ViewBuilder
    private var quickAddSection: some View {
        Section(header: Text("Quick-add")) {
            // Photo preview when image exists
            if shouldShowPhotoUpload, let imageData = documentImage, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture { }
                    
                    Button {
                        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.3)) { documentImage = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(8)
                            .background(Circle().fill(.white))
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                    }
                    .padding(10)
                    .buttonStyle(.borderless)
                }
                .padding(12)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .padding(.bottom, 2)
                )
                .listRowSeparator(.hidden)
            }
            
            // Scan (Passport / Boarding Pass / Event / Hotel Key)
            if type == .passport || type == .boardingPass || type == .event || type == .hotelKeyCard {
                Button(action: {
                    if ScannerView.isSupported {
                        showScanner = true
                    } else {
                        showScannerUnavailableAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                        Text(type == .hotelKeyCard ? "Scan Hotel Key" : "Scan \(type.displayName)")
                    }
                    .foregroundColor(.blue)
                }
                if type == .event {
                    PhotosPicker(
                        selection: $barcodeScreenshotItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            if isExtractingBarcode { ProgressView().padding(.trailing, 6) }
                            Image(systemName: "photo.badge.plus")
                            Text(isExtractingBarcode ? "Reading…" : "Import barcode from screenshot")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(isExtractingBarcode)
                    if barcodePayload != nil {
                        Label("Barcode will appear on card", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Take Photo
            if shouldShowPhotoUpload {
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .foregroundColor(.blue)
                }
                
                // Choose Photo
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(documentImage == nil ? "Choose Photo" : "Change Photo")
                    }
                    .foregroundColor(.blue)
                }
                if type == .rewardsCard {
                    PhotosPicker(
                        selection: $barcodeScreenshotItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            if isExtractingBarcode { ProgressView().padding(.trailing, 6) }
                            Image(systemName: "photo.badge.plus")
                            Text(isExtractingBarcode ? "Reading…" : "Import barcode from screenshot")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(isExtractingBarcode)
                    if barcodePayload != nil {
                        Label("Barcode will appear on card", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var documentDetailsSection: some View {
        Section(header: Text("Card Details")) {
            switch type {
            case .medicalAlert:
                Picker("Blood Type", selection: $selectedBloodType) {
                    ForEach(bloodTypes, id: \.self) { Text($0) }
                }
                TextField("Allergies (e.g. Peanuts, Penicillin)", text: $allergies)
                    .textInputAutocapitalization(.words)
            case .vaccineRecord:
                 TextField("Provider / Clinic", text: $title)
                     .textInputAutocapitalization(.words)
                     
                 Picker("Vaccine Type", selection: $selectedVaccine) {
                     ForEach(vaccines, id: \.self) { Text($0) }
                 }
                 
                 Picker("Manufacturer", selection: $manufacturer) {
                    ForEach(vaccineManufacturers, id: \.self) { Text($0) }
                 }
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
                
            case .passport, .idCard:
                Picker(type == .passport ? "Country" : "Issuing Country", selection: $title) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .onChange(of: title) { newValue in
                    nationality = newValue
                }
            case .nationalInsurance:
                Picker("Issuing Country", selection: $nationality) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
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
            
            case .birthCertificate:
                TextField("Issuing Authority", text: $issuingAuthority)
                    .textInputAutocapitalization(.words)
                TextField("Registration District", text: $registrationDistrict)
                    .textInputAutocapitalization(.words)
                TextField("Certificate Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
            
            case .marriageCertificate:
                TextField("Issuing Authority", text: $issuingAuthority)
                    .textInputAutocapitalization(.words)
                TextField("Place of Marriage", text: $marriagePlace)
                    .textInputAutocapitalization(.words)
                TextField("Marriage License/Cert Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                
            case .studentID:
                Group {
                    TextField("University", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("Your Name", text: $holderName)
                        .textInputAutocapitalization(.words)
                    TextField("Student number", text: $detailValue)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: detailValue) { newValue in
                            detailValue = newValue.uppercased()
                        }
                    DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)
                }
                
            case .event:
                Picker("Event Type", selection: $selectedEventType) {
                    ForEach(eventTypes, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: selectedEventType) { newValue in
                    subtitle = newValue
                }
                
                TextField("Event Name", text: $title)
                    .textInputAutocapitalization(.words)
                
                TextField("Venue Name", text: $venueName)
                    .textInputAutocapitalization(.words)
                
                TextField("Venue Location", text: $venueLocation)
                    .textInputAutocapitalization(.words)
                
                DatePicker("Event Date", selection: $eventDate)
                
                Picker("Ticket Type", selection: $ticketType) {
                    ForEach(ticketTypeOptions, id: \.self) { Text($0).tag($0) }
                }
                
                HStack {
                    TextField("Section", text: $section)
                    Divider()
                    TextField("Row", text: $row)
                    Divider()
                    TextField("Seat", text: $seat)
                }
                
            case .hotelKeyCard:
                Picker("Hotel", selection: $selectedHotelBrand) {
                    Text("Select Brand").tag("")
                    ForEach(hotelBrands, id: \.self) { brand in
                        Text(brand).tag(brand)
                    }
                }
                .onChange(of: selectedHotelBrand) { newValue in
                    title = newValue
                    subtitle = "Hotel Key"
                }
                
                if selectedHotelBrand.isEmpty {
                    TextField("Or enter custom name", text: $title)
                        .textInputAutocapitalization(.words)
                }
                
                Picker("Room Type", selection: $selectedRoomType) {
                    ForEach(roomTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
            case .prescription:
                TextField("Medication Name", text: $title)
                    .textInputAutocapitalization(.words)
                TextField("Dosage (e.g. 500mg)", text: $subtitle)
                    .textInputAutocapitalization(.words)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach(prescriptionFrequencies, id: \.self) { Text($0) }
                }
                
                Picker("Route", selection: $route) {
                    ForEach(prescriptionRoutes, id: \.self) { Text($0) }
                }
                
                Picker("Refills", selection: $refills) {
                    ForEach(refillOptions, id: \.self) { Text($0) }
                }
                
            case .carRental:
                Picker("Rental Company", selection: $selectedCarBrand) {
                    Text("Select Company").tag("")
                    ForEach(carRentalCompanies, id: \.self) { company in
                        Text(company).tag(company)
                    }
                }
                .onChange(of: selectedCarBrand) { newValue in
                    title = newValue
                    subtitle = "Car Rental"
                }
                
                if selectedCarBrand.isEmpty {
                    TextField("Or enter custom name", text: $title)
                        .textInputAutocapitalization(.words)
                }
                
                TextField("Car Model (e.g. VW Golf)", text: $carModel)
                    .textInputAutocapitalization(.words)
                
            case .rewardsCard:
                Picker("Card Type", selection: $selectedRewardType) {
                    ForEach(rewardTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .onChange(of: selectedRewardType) { _ in
                    selectedRewardBrand = ""
                    title = ""
                }
                
                if selectedRewardType == "Coffee" {
                    Picker("Coffee Shop", selection: $selectedRewardBrand) {
                        Text("Select Brand").tag("")
                        ForEach(coffeeShops, id: \.self) { shop in
                            Text(shop).tag(shop)
                        }
                    }
                    .onChange(of: selectedRewardBrand) { newValue in
                        title = newValue
                        subtitle = "Coffee Rewards"
                    }
                } else if selectedRewardType == "Airline" {
                    Picker("Airline", selection: $selectedRewardBrand) {
                        Text("Select Airline").tag("")
                        ForEach(airlineSegments, id: \.country) { segment in
                            Section(header: Text(segment.country)) {
                                ForEach(segment.airlines, id: \.self) { airline in
                                    Text(airline).tag(airline)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedRewardBrand) { newValue in
                        title = newValue
                        subtitle = "Frequent Flyer"
                    }
                    Picker("Tier", selection: $selectedAirlineTier) {
                        Text("Bronze").tag("Bronze")
                        Text("Silver").tag("Silver")
                        Text("Gold").tag("Gold")
                    }
                } else if selectedRewardType == "Supermarket" {
                    Picker("Supermarket", selection: $selectedRewardBrand) {
                        Text("Select Supermarket").tag("")
                        ForEach(supermarkets, id: \.self) { market in
                            Text(market).tag(market)
                        }
                    }
                    .onChange(of: selectedRewardBrand) { newValue in
                        title = newValue
                        subtitle = "Supermarket Rewards"
                    }
                }
                
                if selectedRewardBrand.isEmpty {
                    TextField("Or enter custom name", text: $title)
                        .textInputAutocapitalization(.words)
                }
            
            case .petInsurance:
                TextField("Insurance Provider", text: $title)
                    .textInputAutocapitalization(.words)
                TextField("Plan Type", text: $subtitle)
                    .textInputAutocapitalization(.words)
                
            case .petVaccineRecord:
                TextField("Clinic / Vet Name", text: $title)
                    .textInputAutocapitalization(.words)
                TextField("Vaccine Name", text: $subtitle)
                    .textInputAutocapitalization(.words)
                
            case .petPassport:
                Picker("Issuing Country", selection: $title) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                
            case .petID:
                TextField("Issuing Authority", text: $title)
                    .textInputAutocapitalization(.words)
                TextField("Registration Type", text: $subtitle)
                    .textInputAutocapitalization(.words)
            }
        }
    }
    
    private var personalInfoSection: some View {
        Section(header: Text(isPetDocument ? "Pet Info" : (type == .medicalAlert ? "Emergency Contact" : "Personal Info"))) {
            switch type {
            case .petInsurance:
                TextField("Pet Name", text: $petName)
                    .textInputAutocapitalization(.words)
                Picker("Species", selection: $petSpecies) {
                    ForEach(petSpeciesList, id: \.self) { Text($0).tag($0) }
                }
                TextField("Breed (Optional)", text: $petBreed)
                    .textInputAutocapitalization(.words)
                TextField("Policy Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                
                DatePicker("Start Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("End Date", selection: $expiryDate, displayedComponents: .date)
                
            case .petVaccineRecord:
                TextField("Pet Name", text: $petName)
                    .textInputAutocapitalization(.words)
                Picker("Species", selection: $petSpecies) {
                    ForEach(petSpeciesList, id: \.self) { Text($0).tag($0) }
                }
                TextField("Batch / Dose Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                DatePicker("Date Administered", selection: $issueDate, displayedComponents: .date)
                DatePicker("Next Due", selection: $expiryDate, displayedComponents: .date)
                
            case .petPassport, .petID:
                TextField("Pet Name", text: $petName)
                    .textInputAutocapitalization(.words)
                Picker("Species", selection: $petSpecies) {
                    ForEach(petSpeciesList, id: \.self) { Text($0).tag($0) }
                }
                TextField("Breed", text: $petBreed)
                    .textInputAutocapitalization(.words)
                TextField("Microchip Number", text: $petMicrochipNumber)
                    .textInputAutocapitalization(.characters)
                
                if type == .petPassport {
                    DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                }
                DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                
            case .medicalAlert:
                TextField("Full Name", text: $emergencyContactName)
                    .textInputAutocapitalization(.words)
                TextField("Phone Number", text: $emergencyPhoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email", text: $emergencyContactEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            
            case .birthCertificate:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                Picker("Gender", selection: $selectedGender) {
                    ForEach(genderOptions, id: \.self) { Text($0) }
                }
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                TextField("Place of Birth", text: $placeOfBirth)
                    .textInputAutocapitalization(.words)
                TextField("Father's Full Name", text: $fatherName)
                    .textInputAutocapitalization(.words)
                TextField("Mother's Full Name", text: $motherName)
                    .textInputAutocapitalization(.words)
                DatePicker("Registration Date", selection: $issueDate, displayedComponents: .date)

            case .marriageCertificate:
                TextField("Spouse 1 Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Spouse 2 Full Name", text: $spouseName)
                    .textInputAutocapitalization(.words)
                DatePicker("Date of Marriage", selection: $marriageDate, displayedComponents: [.date])
                TextField("Officiant Name", text: $officiantName)
                    .textInputAutocapitalization(.words)
                TextField("Witnesses", text: $witnesses)
                    .textInputAutocapitalization(.words)
                
            case .visa:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Visa Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                        visaNumber = detailValue
                    }
                TextField("Passport Number", text: $passportNumber)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: passportNumber) { newValue in
                        passportNumber = newValue.uppercased()
                    }
                
                Picker("Issuing Country", selection: $nationality) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                
                Picker("Number of Entries", selection: $entries) {
                    Text("Single").tag("Single")
                    Text("Double").tag("Double")
                    Text("Multiple").tag("Multiple")
                }
                
                TextField("Issuing Authority", text: $issuingAuthority)
                    .textInputAutocapitalization(.words)
                
                TextField("Place of Issue", text: $placeOfIssue)
                    .textInputAutocapitalization(.words)
                
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                
                TextField("Remarks / Annotations", text: $visaRemarks, axis: .vertical)
                    .lineLimit(3)

            case .passport:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Passport Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
                
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                DatePicker("Date of Expiry", selection: $expiryDate, displayedComponents: .date)

            case .vaccineRecord:
                TextField("Patient Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                
                Picker("Dose", selection: $dose) {
                    ForEach(doseOptions, id: \.self) { Text($0) }
                }
                
                TextField("Batch Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                
                DatePicker("Date Administered", selection: $issueDate, displayedComponents: .date)
                DatePicker("Next Due (Optional)", selection: $expiryDate, displayedComponents: .date)
                
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

            case .idCard, .nationalInsurance:
                TextField("Full Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField(type == .idCard ? "ID Number" : "NI Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
                DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)

            case .studentID:
                EmptyView() // Student ID fields live in Card Details section
            
            case .carRental:
                TextField("Driver Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Reservation Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                
                TextField("Pick-up Location", text: $pickupLocation)
                    .textInputAutocapitalization(.words)
                DatePicker("Pick-up Date & Time", selection: $pickupDate)
                
                TextField("Drop-off Location", text: $dropoffLocation)
                    .textInputAutocapitalization(.words)
                DatePicker("Drop-off Date & Time", selection: $dropoffDate)
                
            case .hotelKeyCard:
                TextField("Guest Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("Room Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                TextField("Reservation Number", text: $reservationNumber)
                    .textInputAutocapitalization(.characters)
                TextField("Loyalty / Member Number", text: $loyaltyNumber)
                    .textInputAutocapitalization(.characters)
                
                DatePicker("Check-in Date", selection: $issueDate, displayedComponents: .date)
                DatePicker("Check-out Date", selection: $expiryDate, displayedComponents: .date)
                
                TextField("Wi-Fi Password", text: $wifiPassword)
                TextField("Hotel Phone", text: $hotelPhoneNumber)
                    .keyboardType(.phonePad)
                TextField("Hotel Address", text: $hotelAddress, axis: .vertical)
                    .lineLimit(3)
                
            case .prescription:
                TextField("Patient Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField("RX Number", text: $detailValue)
                    .textInputAutocapitalization(.characters)
                
                TextField("Prescribing Doctor", text: $doctorName)
                    .textInputAutocapitalization(.words)
                TextField("Pharmacy Name", text: $pharmacyName)
                    .textInputAutocapitalization(.words)
                
                DatePicker("Date Prescribed", selection: $issueDate, displayedComponents: .date)
                DatePicker("Expiration Date", selection: $expiryDate, displayedComponents: .date)
                
            default:
                TextField("Your Name", text: $holderName)
                    .textInputAutocapitalization(.words)
                TextField(getDetailLabel(), text: $detailValue)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: detailValue) { newValue in
                        detailValue = newValue.uppercased()
                    }
                if type == .boardingPass {
                    PhotosPicker(
                        selection: $barcodeScreenshotItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            if isExtractingBarcode { ProgressView().padding(.trailing, 6) }
                            Image(systemName: "photo.badge.plus")
                            Text(isExtractingBarcode ? "Reading…" : "Import barcode from screenshot")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(isExtractingBarcode)
                    if barcodePayload != nil {
                        Label("Barcode will appear on card", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - SCANNER LOGIC
    var scannerDataTypes: Set<DataScannerViewController.RecognizedDataType> {
        switch type {
        case .passport:
            return [.text(textContentType: nil)]
        case .boardingPass, .event, .hotelKeyCard:
            return [.barcode(symbologies: [.qr, .aztec, .pdf417, .code128, .code39, .ean8, .ean13, .upce])]
        default:
            return []
        }
    }
    
    func handleScanResult(_ result: ScanResult) {
        switch result {
        case .passport(let data):
            holderName = "\(data.firstName) \(data.lastName)"
            detailValue = data.documentNumber
            
            // Sync Picker with Scanned Nationality
            // We trim whitespace and do a case-insensitive match against the countries list
            let cleanNationality = data.nationality.trimmingCharacters(in: .whitespacesAndNewlines)
            if let matchedCountry = countries.first(where: { $0.localizedCaseInsensitiveCompare(cleanNationality) == .orderedSame }) {
                title = matchedCountry
                nationality = matchedCountry
            } else {
                title = cleanNationality
                nationality = cleanNationality
            }
            
            if let dob = data.birthDate { birthDate = dob }
            if let exp = data.expiryDate { expiryDate = exp }
            
        case .boardingPass(let data):
            holderName = data.name
            detailValue = data.flightNumber
            barcodePayload = data.rawPayload

            // Map Carrier Code to Name
            let carrierCode = data.carrier.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let airlineMapping: [String: String] = [
                "BA": "British Airways", "BAW": "British Airways",
                "U2": "easyJet", "EZY": "easyJet",
                "VS": "Virgin Atlantic", "VIR": "Virgin Atlantic",
                "AA": "American Airlines", "AAL": "American Airlines",
                "DL": "Delta", "DAL": "Delta",
                "UA": "United", "UAL": "United",
                "QF": "Qantas", "QFA": "Qantas",
                "AC": "Air Canada", "ACA": "Air Canada",
                "CA": "Air China", "CCA": "Air China",
                "LH": "Lufthansa", "DLH": "Lufthansa",
                "FR": "Ryanair", "RYR": "Ryanair",
                "JL": "Japan Airlines", "JAL": "Japan Airlines",
                "QR": "Qatar Airways", "QTR": "Qatar Airways",
                "SQ": "Singapore Airlines", "SIA": "Singapore Airlines",
                "EK": "Emirates", "UAE": "Emirates"
            ]
            
            if let airlineName = airlineMapping[carrierCode] {
                selectedAirline = airlineName
            } else {
                selectedAirline = data.carrier // Fallback
            }
            
            // Lookup origin
            if let foundOrigin = airports.first(where: { $0.0 == data.origin }) {
                origin = "\(foundOrigin.1) (\(foundOrigin.0))"
            } else {
                origin = data.origin
            }
            
            // Lookup destination (title)
            if let foundDest = airports.first(where: { $0.0 == data.destination }) {
                title = "\(foundDest.1) (\(foundDest.0))"
            } else {
                title = data.destination
            }
            
            if let seatNum = data.seat { seat = seatNum }
            if let fDate = data.flightDate { flightDate = fDate }
            
            // Map Class Code
            if let classCode = data.classCode {
                switch classCode {
                case "F", "A", "P":
                    flightClass = "First"
                case "C", "J", "D", "I", "Z":
                    flightClass = "Business"
                case "W", "E":
                    flightClass = "Premium Economy"
                case "Y", "B", "H", "K", "M", "L", "V", "S", "N", "Q", "O", "G", "X":
                    flightClass = "Economy"
                default:
                    flightClass = "Economy"
                }
            }
        case .generic(let payload):
            // Auto-recognition for general tickets
            detailValue = payload
            barcodePayload = payload

            // Simple heuristics for ticket data
            // If it's a long alphanumeric string, it's likely a confirmation code
            // If we are in .event mode, we can try to pre-fill
            if type == .event {
                // If payload contains typical ticket patterns, we can extract them
                // For now, let's just put the whole payload in Ticket Number
                detailValue = payload
            }
        }
    }
    
    private func getDetailLabel() -> String {
        switch type {
        case .studentID:
            return "Student number"
        case .visa:
            return "Visa Number"
        case .rewardsCard:
            return "Member Number"
        case .event:
            return "Ticket Number"
        case .carRental:
            return "Reservation Number"
        case .hotelKeyCard:
            return "Room / Res Number"
        case .idCard:
            return "ID Number"
        case .nationalInsurance:
            return "NI Number"
        case .petInsurance:
            return "Policy Number"
        case .petVaccineRecord:
            return "Batch Number"
        case .petPassport, .petID:
            return "ID / Chip Number"
        default:
            return "Booking Number"
        }
    }
    
    var isPetDocument: Bool {
        return [.petInsurance, .petVaccineRecord, .petPassport, .petID].contains(type)
    }
    
    func saveDocument() {
        var finalTitle = title
        var finalSubtitle = subtitle
        var finalHolder = holderName
        var finalDetail = detailValue
        var finalAirline = ""
        var finalAirlineTier: String? = nil
        
        switch type {
        case .medicalAlert:
            let bloodTypePart = "TYPE: \(selectedBloodType)"
            finalHolder = bloodTypePart
            finalTitle = "Medical Card"
            finalSubtitle = "Blood Type"
            
        case .vaccineRecord:
            if finalTitle.isEmpty { finalTitle = "Vaccination" }
            if !dose.isEmpty {
                 finalSubtitle = "\(selectedVaccine) - \(dose)"
            } else {
                 finalSubtitle = selectedVaccine
            }
            
        case .boardingPass:
            finalAirline = selectedAirline
            
        case .insurance:
            // Only append " Insurance" if not already present (avoids "Health Insurance Insurance" on re-save)
            let trimmed = subtitle.trimmingCharacters(in: .whitespaces)
            finalSubtitle = trimmed.lowercased().hasSuffix("insurance") ? subtitle : subtitle + " Insurance"
            
        case .driversLicense:
            finalSubtitle = "Driver License"

        case .idCard:
            finalSubtitle = "National ID"

        case .nationalInsurance:
            finalSubtitle = "NI Number"

        case .studentID:
            finalSubtitle = "Student ID"
            
        case .prescription:
            if finalSubtitle.isEmpty { finalSubtitle = "Prescription" }
            
        case .birthCertificate:
            finalTitle = "Birth Certificate"
            finalSubtitle = "Official Record"
            
        case .marriageCertificate:
            finalTitle = "Marriage Certificate"
            finalSubtitle = "Official Record"
            
        case .rewardsCard:
            if finalSubtitle.isEmpty || finalSubtitle == "LOYALTY" {
                finalSubtitle = "Loyalty Card"
            }
            if selectedRewardType == "Airline" {
                finalAirline = selectedRewardBrand
                finalAirlineTier = selectedAirlineTier
            }
            
        case .event:
            finalSubtitle = "Admission Ticket"
            
        case .carRental:
            finalSubtitle = "Rental Agreement"
            
        case .hotelKeyCard:
            finalSubtitle = "Hotel Key"
            
        case .petInsurance:
            if finalSubtitle.isEmpty { finalSubtitle = "Pet Insurance" }
        case .petVaccineRecord:
            if finalSubtitle.isEmpty { finalSubtitle = "Vaccination" }
        case .petPassport:
            finalSubtitle = "Pet Passport"
        case .petID:
            if finalSubtitle.isEmpty { finalSubtitle = "Pet ID" }
            
        default:
            break
        }
        
        if finalTitle.isEmpty { finalTitle = "New Document" }
        if finalSubtitle.isEmpty { finalSubtitle = type.displayName }
        
        // PET NAME HANDLING
        if isPetDocument {
            finalHolder = petName.isEmpty ? "Pet Name" : petName
        } else if finalHolder.isEmpty {
             finalHolder = "Card Holder"
        }
        
        let newDoc = TravelDocument(
            id: existingID ?? UUID(),
            type: type,
            title: finalTitle,
            subtitle: finalSubtitle,
            holderName: finalHolder,
            detailValue: finalDetail,
            origin: type == .boardingPass ? origin : nil,
            nationality: (type == .passport || type == .driversLicense || type == .idCard || type == .nationalInsurance || type == .visa) ? nationality : nil,
            birthDate: (type == .passport || type == .driversLicense || type == .idCard || type == .nationalInsurance || type == .petPassport || type == .visa) ? birthDate : nil,
            issueDate: (type == .passport || type == .insurance || type == .driversLicense || type == .idCard || type == .nationalInsurance || type == .petInsurance || type == .petVaccineRecord || type == .petPassport || type == .petID || type == .vaccineRecord || type == .visa || type == .prescription || type == .birthCertificate) ? issueDate : nil,
            expiryDate: (type == .passport || type == .insurance || type == .driversLicense || type == .visa || type == .studentID || type == .idCard || type == .nationalInsurance || type == .petInsurance || type == .petVaccineRecord || type == .petPassport || type == .petID || type == .prescription) ? expiryDate : nil,
            gate: type == .boardingPass ? gate : nil,
            seat: (type == .boardingPass || type == .event) ? seat : nil,
            flightClass: type == .boardingPass ? flightClass : nil,
            flightDate: type == .boardingPass ? flightDate : nil,
            boardingTime: type == .boardingPass ? boardingTime : nil,
            emergencyContactName: type == .medicalAlert ? emergencyContactName : nil,
            emergencyContactEmail: type == .medicalAlert ? emergencyContactEmail : nil,
            allergies: type == .medicalAlert ? (allergies.isEmpty ? nil : allergies) : nil,
            groupNumber: type == .insurance ? groupNumber : nil,
            emergencyPhoneNumber: (type == .insurance || type == .medicalAlert) ? emergencyPhoneNumber : nil,
            address: type == .driversLicense ? address : nil,
            licenseClass: type == .driversLicense ? licenseClass : nil,
            restrictions: type == .driversLicense ? restrictions : nil,
            endorsements: type == .driversLicense ? endorsements : nil,
            height: type == .driversLicense ? height : nil,
            eyeColor: type == .driversLicense ? eyeColor : nil,
            documentImageData: (type == .driversLicense || type == .passport || type == .idCard || type == .nationalInsurance || type == .studentID || type == .birthCertificate || type == .marriageCertificate || type == .rewardsCard || type == .event || type == .carRental || type == .hotelKeyCard || type == .petPassport || type == .petID || type == .petInsurance || type == .petVaccineRecord || type == .visa || type == .prescription || type == .vaccineRecord || type == .medicalAlert || type == .insurance) ? documentImage : nil,
            dose: type == .vaccineRecord ? dose : nil,
            manufacturer: type == .vaccineRecord ? manufacturer : nil,
            frequency: type == .prescription ? frequency : nil,
            route: type == .prescription ? route : nil,
            doctorName: type == .prescription ? doctorName : nil,
            pharmacyName: type == .prescription ? pharmacyName : nil,
            refills: type == .prescription ? refills : nil,
            visaNumber: type == .visa ? visaNumber : nil,
            passportNumber: type == .visa ? passportNumber : nil,
            entries: type == .visa ? entries : nil,
            issuingAuthority: (type == .visa || type == .birthCertificate || type == .marriageCertificate) ? issuingAuthority : nil,
            placeOfIssue: type == .visa ? placeOfIssue : nil,
            visaRemarks: type == .visa ? visaRemarks : nil,
            carModel: type == .carRental ? carModel : nil,
            pickupLocation: type == .carRental ? pickupLocation : nil,
            dropoffLocation: type == .carRental ? dropoffLocation : nil,
            pickupDate: type == .carRental ? pickupDate : nil,
            dropoffDate: type == .carRental ? dropoffDate : nil,
            hotelAddress: type == .hotelKeyCard ? hotelAddress : nil,
            hotelPhoneNumber: type == .hotelKeyCard ? hotelPhoneNumber : nil,
            reservationNumber: type == .hotelKeyCard ? reservationNumber : nil,
            wifiPassword: type == .hotelKeyCard ? wifiPassword : nil,
            roomType: type == .hotelKeyCard ? selectedRoomType : nil,
            loyaltyNumber: type == .hotelKeyCard ? loyaltyNumber : nil,
            eventType: type == .event ? selectedEventType : nil,
            venueName: type == .event ? venueName : nil,
            venueLocation: type == .event ? venueLocation : nil,
            section: type == .event ? section : nil,
            row: type == .event ? row : nil,
            eventDate: type == .event ? eventDate : nil,
            ticketType: type == .event ? ticketType : nil,
            petName: isPetDocument ? petName : nil,
            petSpecies: isPetDocument ? petSpecies : nil,
            petBreed: isPetDocument ? petBreed : nil,
            petMicrochipNumber: isPetDocument ? petMicrochipNumber : nil,
            vetName: isPetDocument ? vetName : nil,
            placeOfBirth: type == .birthCertificate ? placeOfBirth : nil,
            registrationDistrict: type == .birthCertificate ? registrationDistrict : nil,
            fatherName: type == .birthCertificate ? fatherName : nil,
            motherName: type == .birthCertificate ? motherName : nil,
            gender: type == .birthCertificate ? selectedGender : nil,
            spouseName: type == .marriageCertificate ? spouseName : nil,
            marriageDate: type == .marriageCertificate ? marriageDate : nil,
            marriagePlace: type == .marriageCertificate ? marriagePlace : nil,
            officiantName: type == .marriageCertificate ? officiantName : nil,
            witnesses: type == .marriageCertificate ? witnesses : nil,
            primaryColor: subscriptionManager.isPro ? customPrimaryColor : getColor(for: type),
            secondaryColor: subscriptionManager.isPro ? customSecondaryColor : .white,
            iconName: subscriptionManager.isPro ? selectedIconName : getIcon(for: type),
            airline: finalAirline,
            airlineTier: finalAirlineTier,
            isActive: true,
            createdAt: existingCreatedAt,
            stackOrderIndex: existingStackOrderIndex,
            barcodePayload: type == .boardingPass ? barcodePayload : (type == .rewardsCard || type == .event ? (barcodePayload ?? (detailValue.isEmpty ? nil : detailValue)) : nil)
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
        case .rewardsCard: return Color(red: 0.95, green: 0.75, blue: 0.1)
        case .event: return Color(red: 0.0, green: 0.7, blue: 0.8)
        case .carRental: return Color(red: 0.1, green: 0.4, blue: 0.2)
        case .hotelKeyCard: return Color(red: 0.15, green: 0.15, blue: 0.2)
        case .passport: return Color(red: 0.05, green: 0.05, blue: 0.25)
        case .boardingPass: return Color(red: 1.0, green: 0.31, blue: 0.0)
        case .visa: return Color(red: 0.85, green: 0.2, blue: 0.3)
        case .insurance: return Color(red: 0.0, green: 0.5, blue: 0.5)
        case .idCard: return Color(red: 0.45, green: 0.2, blue: 0.6)
        case .nationalInsurance: return Color(red: 0.2, green: 0.6, blue: 0.3)
        case .petInsurance: return Color(red: 0.2, green: 0.6, blue: 0.3) // Green
        case .petVaccineRecord: return Color(red: 0.2, green: 0.4, blue: 0.7) // Same as vaccine
        case .petPassport: return Color(red: 0.5, green: 0.1, blue: 0.2) // Burgundy
        case .petID: return Color(red: 0.8, green: 0.4, blue: 0.0) // Orange
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
        case .rewardsCard: return "star.fill"
        case .event: return "ticket.fill"
        case .carRental: return "car.2.fill"
        case .hotelKeyCard: return "key.fill"
        case .passport: return "globe"
        case .boardingPass: return "airplane"
        case .visa: return "checkmark.seal"
        case .insurance: return "cross.case.fill"
        case .idCard: return "person.text.rectangle"
        case .nationalInsurance: return "number.square.fill"
        case .petInsurance: return "cross.case.fill"
        case .petVaccineRecord: return "syringe.fill"
        case .petPassport: return "pawprint.fill"
        case .petID: return "pawprint.fill"
        }
    }
    
    /// Default icon per type (static for use in init).
    static func getDefaultIcon(for type: TravelDocument.DocumentType) -> String {
        switch type {
        case .driversLicense: return "car.fill"
        case .studentID: return "graduationcap.fill"
        case .prescription: return "pills.fill"
        case .vaccineRecord: return "syringe.fill"
        case .medicalAlert: return "staroflife.fill"
        case .birthCertificate: return "stroller.fill"
        case .marriageCertificate: return "figure.and.child.holdinghands"
        case .rewardsCard: return "star.fill"
        case .event: return "ticket.fill"
        case .carRental: return "car.2.fill"
        case .hotelKeyCard: return "key.fill"
        case .passport: return "globe"
        case .boardingPass: return "airplane"
        case .visa: return "checkmark.seal"
        case .insurance: return "cross.case.fill"
        case .idCard: return "person.text.rectangle"
        case .nationalInsurance: return "number.square.fill"
        case .petInsurance: return "cross.case.fill"
        case .petVaccineRecord: return "syringe.fill"
        case .petPassport: return "pawprint.fill"
        case .petID: return "pawprint.fill"
        }
    }
    
    /// PRO: Contextual icon options per document type (SF Symbol names).
    static func iconOptions(for type: TravelDocument.DocumentType) -> [String] {
        switch type {
        case .driversLicense: return ["car.fill", "truck.box.fill", "bicycle"]
        case .studentID: return ["graduationcap.fill", "book.fill", "person.fill", "building.2.fill"]
        case .prescription: return ["pills.fill", "cross.case.fill", "pill.fill", "staroflife.fill"]
        case .vaccineRecord: return ["syringe.fill", "cross.vial.fill", "heart.fill", "shield.fill"]
        case .medicalAlert: return ["staroflife.fill", "cross.case.fill", "heart.fill", "waveform.path.ecg"]
        case .birthCertificate: return ["stroller.fill", "doc.text.fill", "person.fill", "heart.fill"]
        case .marriageCertificate: return ["figure.and.child.holdinghands", "heart.fill", "heart.circle.fill"]
        case .rewardsCard: return ["star.fill", "gift.fill", "tag.fill", "creditcard.fill"]
        case .event: return ["ticket.fill", "music.note", "calendar", "theatermasks.fill"]
        case .carRental: return ["car.2.fill", "car.fill", "key.fill", "fuelpump.fill"]
        case .hotelKeyCard: return ["key.fill", "building.2.fill", "bed.double.fill", "house.fill"]
        case .passport: return ["globe", "doc.text.fill", "map.fill", "airplane"]
        case .boardingPass: return ["airplane", "airplane.departure", "airplane.arrival"]
        case .visa: return ["checkmark.seal", "doc.text.fill", "globe", "map.fill"]
        case .insurance: return ["cross.case.fill", "shield.fill", "heart.fill", "cross.vial.fill"]
        case .idCard: return ["person.text.rectangle", "person.fill", "creditcard.fill", "doc.text.fill"]
        case .nationalInsurance: return ["number.square.fill", "doc.text.fill", "person.text.rectangle"]
        case .petInsurance: return ["cross.case.fill", "pawprint.fill", "heart.fill"]
        case .petVaccineRecord: return ["syringe.fill", "pawprint.fill", "cross.vial.fill"]
        case .petPassport: return ["pawprint.fill", "globe", "doc.text.fill"]
        case .petID: return ["pawprint.fill", "heart.fill", "tag.fill"]
        }
    }
}

// MARK: - Card Customisation sub-screen (Pro)
fileprivate struct CardCustomisationView: View {
    @Binding var customPrimaryColor: Color
    @Binding var selectedIconName: String
    @Binding var rememberColorForFuture: Bool
    @Binding var rememberIconForFuture: Bool
    let type: TravelDocument.DocumentType
    
    private func saveRememberedColor() {
        let c = CodableColor(color: customPrimaryColor)
        let s = "\(c.red),\(c.green),\(c.blue)"
        UserDefaults.standard.set(s, forKey: DocumentFormView.rememberedColorKey(type))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Card Colour")) {
                ColorPicker("Primary colour", selection: $customPrimaryColor, supportsOpacity: false)
                Toggle("Remember for future cards", isOn: $rememberColorForFuture)
                    .onChange(of: rememberColorForFuture) { _, on in
                        UserDefaults.standard.set(on, forKey: DocumentFormView.rememberColorKey(type))
                        if on { saveRememberedColor() }
                    }
                    .onChange(of: customPrimaryColor) { _, _ in
                        if rememberColorForFuture { saveRememberedColor() }
                    }
            }
            Section(header: Text("Card Icon")) {
                let options = DocumentFormView.iconOptions(for: type)
                let displayOptions = options.contains(selectedIconName) ? options : options + [selectedIconName]
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 52), spacing: 12)
                    ], spacing: 12) {
                        ForEach(displayOptions, id: \.self) { iconName in
                            Button {
                                selectedIconName = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIconName == iconName ? .white : .primary)
                                    .frame(width: 52, height: 52)
                                    .background(selectedIconName == iconName ? Color.blue : Color.primary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
                Toggle("Remember for future cards", isOn: $rememberIconForFuture)
                    .onChange(of: rememberIconForFuture) { _, on in
                        UserDefaults.standard.set(on, forKey: DocumentFormView.rememberIconKey(type))
                        if on { UserDefaults.standard.set(selectedIconName, forKey: DocumentFormView.rememberedIconKey(type)) }
                    }
                    .onChange(of: selectedIconName) { _, new in
                        if rememberIconForFuture { UserDefaults.standard.set(new, forKey: DocumentFormView.rememberedIconKey(type)) }
                    }
            }
        }
        .navigationTitle("Card Customisation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
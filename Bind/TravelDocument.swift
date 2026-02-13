import SwiftUI

// MARK: - 1. DATA MODELS
struct TravelDocument: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let type: DocumentType
    let title: String
    let subtitle: String
    let holderName: String
    let detailValue: String
    
    // NEW FIELDS (Optional to maintain backward compatibility with JSON)
    var origin: String? // NEW: For Boarding Pass
    var nationality: String?
    var birthDate: Date?
    var issueDate: Date? // Used for Insurance Start Date & License Issue
    var expiryDate: Date? // Used for Insurance End Date & License Expiry
    
    // NEW: Boarding Pass Specific Fields
    var gate: String?
    var seat: String?
    var flightClass: String?
    var flightDate: Date?
    var boardingTime: Date?
    
    // NEW: Medical Card Specific Fields
    var emergencyContactName: String?
    var emergencyContactEmail: String?
    var allergies: String?

    // NEW: Insurance Specific Fields
    var groupNumber: String?
    var emergencyPhoneNumber: String?
    
    // NEW: Driver's License Specific Fields
    var address: String?
    var licenseClass: String?
    var restrictions: String?
    var endorsements: String?
    var height: String?
    var eyeColor: String?
    var documentImageData: Data?
    
    // NEW: Vaccine Specific Fields
    var dose: String?
    var manufacturer: String?
    
    // NEW: Prescription Specific Fields
    var frequency: String?
    var route: String?
    var doctorName: String?
    var pharmacyName: String?
    var refills: String?
    
    // NEW: Visa Specific Fields
    var visaNumber: String?
    var passportNumber: String?
    var entries: String? // Single, Double, Multiple
    var issuingAuthority: String?
    var placeOfIssue: String?
    var visaRemarks: String?
    
    // NEW: Car Rental Specific Fields
    var carModel: String?
    var pickupLocation: String?
    var dropoffLocation: String?
    var pickupDate: Date?
    var dropoffDate: Date?
    
    // NEW: Pet Specific Fields
    var petName: String?
    var petSpecies: String?
    var petBreed: String?
    var petMicrochipNumber: String?
    var vetName: String?
    
    // NEW: Hotel Key Card Specific Fields
    var hotelAddress: String?
    var hotelPhoneNumber: String?
    var reservationNumber: String?
    var wifiPassword: String?
    var roomType: String?
    var loyaltyNumber: String?

    // NEW: Event Specific Fields
    var eventType: String?
    var venueName: String?
    var venueLocation: String?
    var section: String?
    var row: String?
    var eventDate: Date?
    var ticketType: String?

    // NEW: Birth Certificate Specific Fields
    var placeOfBirth: String?
    var registrationDistrict: String?
    var fatherName: String?
    var motherName: String?
    var gender: String?

    // NEW: Marriage Certificate Specific Fields
    var spouseName: String?
    var marriageDate: Date?
    var marriagePlace: String?
    var officiantName: String?
    var witnesses: String?

    // Internal storage for Codable colors
    private let primaryColorData: CodableColor
    private let secondaryColorData: CodableColor
    
    let iconName: String
    let airline: String
    var isActive: Bool = true // Toggle state property
    
    // Public computed properties for View usage
    var primaryColor: Color { primaryColorData.color }
    var secondaryColor: Color { secondaryColorData.color }
    
    var displayTitle: String {
        if type == .birthCertificate { return "Birth Certificate" }
        if type == .marriageCertificate { return "Marriage Certificate" }
        return title
    }
    
    // Custom Initializer to handle Color -> Codable conversion transparently
    init(id: UUID = UUID(),
         type: DocumentType,
         title: String,
         subtitle: String,
         holderName: String,
         detailValue: String,
         origin: String? = nil,
         nationality: String? = nil,
         birthDate: Date? = nil,
         issueDate: Date? = nil,
         expiryDate: Date? = nil,
         gate: String? = nil,
         seat: String? = nil,
         flightClass: String? = nil,
         flightDate: Date? = nil,
         boardingTime: Date? = nil,
         emergencyContactName: String? = nil,
         emergencyContactEmail: String? = nil,
         allergies: String? = nil,
         groupNumber: String? = nil,
         emergencyPhoneNumber: String? = nil,
         address: String? = nil,
         licenseClass: String? = nil,
         restrictions: String? = nil,
         endorsements: String? = nil,
         height: String? = nil,
         eyeColor: String? = nil,
         documentImageData: Data? = nil,
         dose: String? = nil,
         manufacturer: String? = nil,
         frequency: String? = nil,
         route: String? = nil,
         doctorName: String? = nil,
         pharmacyName: String? = nil,
         refills: String? = nil,
         visaNumber: String? = nil,
         passportNumber: String? = nil,
         entries: String? = nil,
         issuingAuthority: String? = nil,
         placeOfIssue: String? = nil,
         visaRemarks: String? = nil,
         carModel: String? = nil,
         pickupLocation: String? = nil,
         dropoffLocation: String? = nil,
         pickupDate: Date? = nil,
         dropoffDate: Date? = nil,
         hotelAddress: String? = nil,
         hotelPhoneNumber: String? = nil,
         reservationNumber: String? = nil,
         wifiPassword: String? = nil,
         roomType: String? = nil,
         loyaltyNumber: String? = nil,
         eventType: String? = nil,
         venueName: String? = nil,
         venueLocation: String? = nil,
         section: String? = nil,
         row: String? = nil,
         eventDate: Date? = nil,
         ticketType: String? = nil,
         petName: String? = nil,
         petSpecies: String? = nil,
         petBreed: String? = nil,
         petMicrochipNumber: String? = nil,
         vetName: String? = nil,
         placeOfBirth: String? = nil,
         registrationDistrict: String? = nil,
         fatherName: String? = nil,
         motherName: String? = nil,
         gender: String? = nil,
         spouseName: String? = nil,
         marriageDate: Date? = nil,
         marriagePlace: String? = nil,
         officiantName: String? = nil,
         witnesses: String? = nil,
         primaryColor: Color,
         secondaryColor: Color,
         iconName: String,
         airline: String,
         isActive: Bool = true) {
        
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.holderName = holderName
        self.detailValue = detailValue
        self.origin = origin
        self.nationality = nationality
        self.birthDate = birthDate
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.gate = gate
        self.seat = seat
        self.flightClass = flightClass
        self.flightDate = flightDate
        self.boardingTime = boardingTime
        self.emergencyContactName = emergencyContactName
        self.emergencyContactEmail = emergencyContactEmail
        self.allergies = allergies
        self.groupNumber = groupNumber
        self.emergencyPhoneNumber = emergencyPhoneNumber
        self.address = address
        self.licenseClass = licenseClass
        self.restrictions = restrictions
        self.endorsements = endorsements
        self.height = height
        self.eyeColor = eyeColor
        self.documentImageData = documentImageData
        self.dose = dose
        self.manufacturer = manufacturer
        self.frequency = frequency
        self.route = route
        self.doctorName = doctorName
        self.pharmacyName = pharmacyName
        self.refills = refills
        self.visaNumber = visaNumber
        self.passportNumber = passportNumber
        self.entries = entries
        self.issuingAuthority = issuingAuthority
        self.placeOfIssue = placeOfIssue
        self.visaRemarks = visaRemarks
        self.carModel = carModel
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.pickupDate = pickupDate
        self.dropoffDate = dropoffDate
        self.hotelAddress = hotelAddress
        self.hotelPhoneNumber = hotelPhoneNumber
        self.reservationNumber = reservationNumber
        self.wifiPassword = wifiPassword
        self.roomType = roomType
        self.loyaltyNumber = loyaltyNumber
        self.eventType = eventType
        self.venueName = venueName
        self.venueLocation = venueLocation
        self.section = section
        self.row = row
        self.eventDate = eventDate
        self.ticketType = ticketType
        self.petName = petName
        self.petSpecies = petSpecies
        self.petBreed = petBreed
        self.petMicrochipNumber = petMicrochipNumber
        self.vetName = vetName
        self.placeOfBirth = placeOfBirth
        self.registrationDistrict = registrationDistrict
        self.fatherName = fatherName
        self.motherName = motherName
        self.gender = gender
        self.spouseName = spouseName
        self.marriageDate = marriageDate
        self.marriagePlace = marriagePlace
        self.officiantName = officiantName
        self.witnesses = witnesses
        self.primaryColorData = CodableColor(color: primaryColor)
        self.secondaryColorData = CodableColor(color: secondaryColor)
        self.iconName = iconName
        self.airline = airline
        self.isActive = isActive
    }
    
    enum DocumentType: String, CaseIterable, Identifiable, Codable {
        case passport, visa, boardingPass, insurance, idCard, birthCertificate, marriageCertificate
        // NEW TYPES
        case driversLicense, studentID, prescription, vaccineRecord, medicalAlert, nationalInsurance
        case rewardsCard, event, carRental, hotelKeyCard
        // PET TYPES
        case petInsurance, petVaccineRecord, petPassport, petID
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .driversLicense: return "Driver's License"
            case .studentID: return "Student ID"
            case .prescription: return "Prescription"
            case .vaccineRecord: return "Vaccination"
            case .medicalAlert: return "Medical Card"
            case .idCard: return "National ID"
            case .nationalInsurance: return "National Insurance"
            case .visa: return "Visa"
            case .boardingPass: return "Boarding Pass"
            case .birthCertificate: return "Birth Certificate"
            case .marriageCertificate: return "Marriage Certificate"
            case .rewardsCard: return "Rewards Card"
            case .event: return "Event"
            case .carRental: return "Car Rental"
            case .hotelKeyCard: return "Hotel Key Card"
            case .petInsurance: return "Pet Insurance"
            case .petVaccineRecord: return "Pet Vaccination"
            case .petPassport: return "Pet Passport"
            case .petID: return "Pet ID"
            default: return rawValue.capitalized
            }
        }

        /// Category for grouping in All Cards list (matches add-card menu sections)
        var category: String {
            switch self {
            case .passport, .boardingPass, .carRental, .hotelKeyCard, .visa: return "Travel"
            case .driversLicense, .studentID, .idCard, .nationalInsurance: return "Identity"
            case .prescription, .vaccineRecord, .medicalAlert, .insurance: return "Health"
            case .petInsurance, .petVaccineRecord, .petPassport, .petID: return "Pets"
            case .birthCertificate, .marriageCertificate, .rewardsCard, .event: return "Other"
            }
        }

        /// Order of categories for display (matches add-card menu)
        static let categoryOrder = ["Travel", "Identity", "Health", "Pets", "Other"]
    }
}


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
    var issueDate: Date?
    var expiryDate: Date?
    
    // NEW: Boarding Pass Specific Fields
    var gate: String?
    var seat: String?
    var flightClass: String?
    var flightDate: Date?
    var boardingTime: Date?
    
    // Internal storage for Codable colors
    private let primaryColorData: CodableColor
    private let secondaryColorData: CodableColor
    
    let iconName: String
    let airline: String
    var isActive: Bool = true // Toggle state property
    
    // Public computed properties for View usage
    var primaryColor: Color { primaryColorData.color }
    var secondaryColor: Color { secondaryColorData.color }
    
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
        self.primaryColorData = CodableColor(color: primaryColor)
        self.secondaryColorData = CodableColor(color: secondaryColor)
        self.iconName = iconName
        self.airline = airline
        self.isActive = isActive
    }
    
    enum DocumentType: String, CaseIterable, Identifiable, Codable {
        case passport, visa, boardingPass, insurance, idCard
        // NEW TYPES
        case driversLicense, studentID, prescription, vaccineRecord, medicalAlert
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .driversLicense: return "Driver's License"
            case .studentID: return "Student ID"
            case .prescription: return "Prescription"
            case .vaccineRecord: return "Vaccination Record"
            case .medicalAlert: return "Medical Alert"
            case .idCard: return "ID Card"
            case .boardingPass: return "Boarding Pass"
            default: return rawValue.capitalized
            }
        }
    }
}

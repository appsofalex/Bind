import SwiftUI

// MARK: - Single card view by type (extracted to reduce ContentView type-check complexity)
struct WalletCardView: View {
    let document: TravelDocument
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        let isPassport = (document.type == .passport)
        let isIDCard = (document.type == .idCard || document.type == .driversLicense || document.type == .studentID || document.type == .nationalInsurance)
        let isBoardingPass = (document.type == .boardingPass)
        let isVisa = (document.type == .visa)
        let isRewardsCard = (document.type == .rewardsCard)
        let isCarRental = (document.type == .carRental)
        let isMedicalAlert = (document.type == .medicalAlert)
        
        Group {
            if isPassport {
                PassportFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if isVisa {
                VisaFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if isMedicalAlert {
                MedicalFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .vaccineRecord {
                VaccinationFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .prescription {
                PrescriptionFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .birthCertificate {
                BirthCertificateFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .marriageCertificate {
                MarriageCertificateFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if isIDCard {
                IDFlipCard(
                    document: document,
                    isSelected: isSelected,
                    onTap: onTap,
                    titleOverride: document.type == .nationalInsurance ? "National ID Number" : (document.type == .studentID ? "Student ID" : nil),
                    subtitleOverride: document.type == .nationalInsurance ? "National ID Number" : (document.type == .studentID ? "Student ID" : nil)
                )
            } else if isBoardingPass {
                BoardingPassAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if isRewardsCard {
                RewardsAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if isCarRental {
                CarRentalAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .hotelKeyCard {
                HotelKeyAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .event {
                EventAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if [.petInsurance, .petVaccineRecord, .petPassport, .petID].contains(document.type) {
                PetAnimatedCard(document: document, isSelected: isSelected, onTap: onTap)
            } else if document.type == .insurance {
                InsuranceFlipCard(document: document, isSelected: isSelected, onTap: onTap)
            } else {
                DocumentCardView(document: document)
                    .onTapGesture(perform: onTap)
            }
        }
    }
}

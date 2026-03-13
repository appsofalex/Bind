import SwiftUI

// MARK: - Card Snapshot Content (expanded/back view per document type)
/// Renders the same content as the expanded card for sharing as an image.
struct CardSnapshotContentView: View {
    let document: TravelDocument

    var body: some View {
        Group {
            switch document.type {
            case .passport:
                PassportInteriorView(document: document, isOpen: true)
            case .visa:
                VisaInteriorView(document: document, isOpen: true)
            case .driversLicense:
                DriversLicenseDetailView(document: document)
            case .studentID:
                StudentIdDetailView(document: document)
            case .nationalInsurance, .idCard:
                IDCardDetailView(document: document)
            case .boardingPass:
                BoardingPassDetailView(document: document, animate: false, forSnapshot: true)
            case .carRental:
                CarRentalBackView(document: document, brandColor: getCarBrandColor(for: document.title))
            case .hotelKeyCard:
                HotelKeyBackView(document: document)
            case .event:
                EventDetailView(document: document, forSnapshot: true)
            case .birthCertificate:
                BirthCertificateDetailView(document: document)
            case .marriageCertificate:
                MarriageCertificateDetailView(document: document)
            case .prescription:
                PrescriptionCardDetailView(document: document)
            case .vaccineRecord:
                VaccinationCardDetailView(document: document)
            case .medicalAlert:
                MedicalCardDetailView(document: document)
            case .petInsurance:
                PetInsuranceDetailView(document: document)
            case .petVaccineRecord:
                PetVaccinationDetailView(document: document)
            case .petPassport, .petID:
                PetPassportDetailView(document: document)
            case .rewardsCard:
                RewardsCardSnapshotView(document: document)
            default:
                DocumentCardView(document: document)
            }
        }
        .frame(width: 390, height: 640)
        .clipped()
    }
}

// MARK: - Rewards card snapshot (static back-style layout for sharing)
private struct RewardsCardSnapshotView: View {
    let document: TravelDocument

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: document.iconName)
                        .foregroundColor(.white)
                    Text(document.title.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(document.primaryColor)

                VStack(spacing: 24) {
                    Text(document.subtitle.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Text("1,250 PTS")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "barcode.viewfinder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 44)
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.bottom, 24)
                }
                .padding(.top, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Share payload (carries data into the sheet so it's always present on creation)
struct SharePayload: Identifiable {
    let id = UUID()
    let fileURL: URL?
    let image: UIImage?
}

// MARK: - Share sheet (native UIActivityViewController)
struct ShareSheet: UIViewControllerRepresentable {
    let payload: SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Pass only ONE item to avoid duplicate saves (file URL *or* image, not both).
        if let url = payload.fileURL {
            return UIActivityViewController(activityItems: [url], applicationActivities: nil)
        }
        if let img = payload.image {
            return UIActivityViewController(activityItems: [img], applicationActivities: nil)
        }
        return UIActivityViewController(activityItems: [], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Render card to image and return for sharing
@MainActor
func renderCardSnapshot(document: TravelDocument) -> UIImage? {
    let content = CardSnapshotContentView(document: document)
    let renderer = ImageRenderer(content: content)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}

/// Renders the card to a temporary PNG file and returns its URL. Caller should delete the file when done (e.g. on share sheet dismiss).
@MainActor
func renderCardSnapshotToFile(document: TravelDocument) -> URL? {
    guard let image = renderCardSnapshot(document: document),
          let data = image.pngData() else { return nil }
    let name = "Bind-\(document.title.replacingOccurrences(of: "/", with: "-")).png"
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(name)
    do {
        try data.write(to: fileURL)
        return fileURL
    } catch {
        return nil
    }
}

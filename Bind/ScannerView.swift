import SwiftUI
import VisionKit

// MARK: - Scanner View
struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedData: ScanResult?
    @Environment(\.dismiss) var dismiss
    
    // The types of items we want to scan
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced, // Ensure this is explicitly balanced
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false, // Disable "Slow Down", "Move closer" etc.
            isHighlightingEnabled: true
        )
        
        // --- CUSTOM OVERLAY ---
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = true // Allow touches for buttons
        scanner.view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: scanner.view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: scanner.view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: scanner.view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: scanner.view.trailingAnchor)
        ])

        // 0. Close Button (Top Left)
        let closeButtonContainer = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        closeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        closeButtonContainer.layer.cornerRadius = 15
        closeButtonContainer.layer.masksToBounds = true
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Action needs to be hooked up via Coordinator or target-action
        // Since we are in makeUIViewController, we can attach target to a coordinator method?
        // Or simpler: use a UIAction (iOS 14+)
        closeButton.addAction(UIAction { [weak scanner] _ in
            scanner?.dismiss(animated: true)
        }, for: .touchUpInside)
        
        closeButtonContainer.contentView.addSubview(closeButton)
        overlayView.addSubview(closeButtonContainer)
        
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: closeButtonContainer.contentView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: closeButtonContainer.contentView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),
            
            closeButtonContainer.widthAnchor.constraint(equalToConstant: 30),
            closeButtonContainer.heightAnchor.constraint(equalToConstant: 30),
            closeButtonContainer.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButtonContainer.leadingAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
        
        // 1. Text Instruction Label
        let label = UILabel()
        label.text = "Rotate phone to landscape & align the bottom 2 lines of passport"
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.cornerRadius = 12 // Rounded more
        label.layer.masksToBounds = true
        
        // --- Added Padding via container view or internal insets logic ---
        // Simpler approach: Make the label larger than its text by adding padding constraints
        
        // 2. Example MRZ Code (Faded Grey) - Only shows in Landscape
        let exampleLabel = UILabel()
        exampleLabel.text = "P<GBRDOE<<JOHN<<<<<<<<<<<<<<<<<<<<\n1234567897GBR9001018M2801019<<<<<<"
        exampleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        exampleLabel.textAlignment = .center
        exampleLabel.numberOfLines = 2
        // Monospaced and larger to be clear
        exampleLabel.font = .monospacedSystemFont(ofSize: 18, weight: .semibold) 
        exampleLabel.translatesAutoresizingMaskIntoConstraints = false
        // Hide initially (portrait default)
        exampleLabel.alpha = 0
        exampleLabel.transform = .identity // Ready for landscape
        
        // Only show overlays for Passport Scanning
        if recognizedDataTypes.contains(.text(textContentType: nil)) {
            // Wrap label in a container to provide padding
            let labelContainer = UIView()
            labelContainer.translatesAutoresizingMaskIntoConstraints = false
            labelContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            labelContainer.layer.cornerRadius = 16
            
            label.backgroundColor = .clear // Remove background from label itself
            labelContainer.addSubview(label)
            
            overlayView.addSubview(labelContainer)
            overlayView.addSubview(exampleLabel)
            
            // Store references
            context.coordinator.exampleLabel = exampleLabel
            context.coordinator.instructionLabel = label
            context.coordinator.instructionContainer = labelContainer
            context.coordinator.overlayView = overlayView
            
            // Enable manual layout for the container to handle rotation positioning precisely
            labelContainer.translatesAutoresizingMaskIntoConstraints = true 
            
            // Define Constraints for Label INSIDE Container (Padding) - these are permanent
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: labelContainer.topAnchor, constant: 12),
                label.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor, constant: -12),
                label.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor, constant: -20),
                
                // Example Code in center (Visual Guide)
                exampleLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
                exampleLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
            ])
            
            // Initial Layout is handled by Coordinator
        }
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    static var isSupported: Bool {
        return DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: ScannerView
        var exampleLabel: UILabel?
        var instructionLabel: UILabel?
        var instructionContainer: UIView?
        var overlayView: UIView?
        
        init(parent: ScannerView) {
            self.parent = parent
            super.init()
            
            // Start listening
            NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
            
            // Trigger layout updates
            DispatchQueue.main.async {
                self.orientationChanged()
            }
        }
        
        @objc func orientationChanged() {
            layoutInstructions()
        }
        
        func layoutInstructions() {
            guard let container = instructionContainer,
                  let overlay = overlayView,
                  let example = exampleLabel,
                  let label = instructionLabel else { return }
            
            let orientation = UIDevice.current.orientation
            let safeArea = overlay.safeAreaInsets
            let screenWidth = overlay.bounds.width
            let screenHeight = overlay.bounds.height
            
            // If frames aren't ready, retry briefly?
            if screenWidth == 0 || screenHeight == 0 { return }
            
            UIView.animate(withDuration: 0.3) {
                switch orientation {
                case .landscapeLeft:
                    // Rotated 90 degrees clockwise relative to portrait
                    // Visual Top is Right Edge
                    example.alpha = 1
                    example.transform = CGAffineTransform(rotationAngle: .pi / 2)
                    
                    // Container Rotation
                    container.transform = .identity // Reset to calculate frame
                    
                    // Calculate size - Width is limited by Screen Height
                    let maxWidth = screenHeight - 60
                    label.preferredMaxLayoutWidth = maxWidth - 40 // Account for padding
                    let size = container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                    
                    container.bounds = CGRect(origin: .zero, size: size)
                    
                    // Position
                    // Visual Top is Screen Right (trailing)
                    // We want visual top padding of 30.
                    // Visual Top of container is its local Top edge (which will point Right)
                    // So we want the Rotated Right Edge (Local Top) to be at Screen Right - 30.
                    // Center X = Screen Width - Safe Area Right - 30 - (Height / 2)
                    
                    let centerX = screenWidth - safeArea.right - 30 - (size.height / 2)
                    let centerY = screenHeight / 2
                    
                    container.center = CGPoint(x: centerX, y: centerY)
                    container.transform = CGAffineTransform(rotationAngle: .pi / 2)
                    
                case .landscapeRight:
                    // Rotated -90 degrees
                    // Visual Top is Left Edge
                    example.alpha = 1
                    example.transform = CGAffineTransform(rotationAngle: -.pi / 2)
                    
                    container.transform = .identity
                    
                    let maxWidth = screenHeight - 60
                    label.preferredMaxLayoutWidth = maxWidth - 40
                    let size = container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                    
                    container.bounds = CGRect(origin: .zero, size: size)
                    
                    // Visual Top is Screen Left
                    // We want visual top padding of 30.
                    // Visual Top of container is Local Top (points Left)
                    // So Rotated Left Edge (Local Top) at Screen Left + 30.
                    // Center X = Safe Area Left + 30 + (Height / 2)
                    
                    let centerX = safeArea.left + 60 + (size.height / 2)
                    let centerY = screenHeight / 2
                    
                    container.center = CGPoint(x: centerX, y: centerY)
                    container.transform = CGAffineTransform(rotationAngle: -.pi / 2)
                    
                case .portrait, .portraitUpsideDown, .faceUp, .faceDown, .unknown:
                    // Default Portrait
                    example.alpha = 0
                    example.transform = .identity
                    
                    container.transform = .identity
                    
                    let maxWidth = screenWidth - 40
                    label.preferredMaxLayoutWidth = maxWidth - 40
                    let size = container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                    
                    container.bounds = CGRect(origin: .zero, size: size)
                    
                    // Top Padding 30
                    let centerX = screenWidth / 2
                    let centerY = safeArea.top + 60 + (size.height / 2)
                    
                    container.center = CGPoint(x: centerX, y: centerY)
                    
                @unknown default:
                    break
                }
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            process(item)
        }
        
        // Auto-scan logic
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let item = addedItems.first {
                process(item)
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let item = updatedItems.first {
                process(item)
            }
        }
        
        func process(_ item: RecognizedItem) {
            switch item {
            case .text(let text):
                // 1. Full Success
                if let passportData = DocumentParser.parsePassportMRZ(text.transcript) {
                    parent.scannedData = .passport(passportData)
                    parent.dismiss()
                    return
                }
                
                // 2. Partial / Potential Match (Option 1 Enhancement)
                if text.transcript.contains("P<") {
                    // Update UI to show detection
                    DispatchQueue.main.async {
                        self.instructionLabel?.text = "Hold Steady..."
                        self.instructionLabel?.textColor = .yellow
                        self.layoutInstructions() // Update layout for new text size
                    }
                } else {
                    // Reset if lost (optional, but good for feedback)
                    DispatchQueue.main.async {
                        self.instructionLabel?.text = "Rotate phone to landscape & align the bottom 2 lines of passport"
                        self.instructionLabel?.textColor = .white
                        self.layoutInstructions()
                    }
                }
                
            case .barcode(let barcode):
                // Attempt to parse Boarding Pass
                if let payload = barcode.payloadStringValue,
                   let boardingPassData = DocumentParser.parseBoardingPass(payload) {
                    parent.scannedData = .boardingPass(boardingPassData)
                    parent.dismiss()
                }
            default:
                break
            }
        }
    }
}

// MARK: - Data Models

enum ScanResult: Equatable {
    case passport(PassportData)
    case boardingPass(BoardingPassData)
}

struct PassportData: Equatable {
    let documentNumber: String
    let expiryDate: Date?
    let birthDate: Date?
    let firstName: String
    let lastName: String
    let nationality: String
}

struct BoardingPassData: Equatable {
    let name: String
    let pnr: String // Booking Ref
    let origin: String
    let destination: String
    let carrier: String
    let flightNumber: String
    let flightDate: Date?
    let seat: String?
    let classCode: String?
}

// MARK: - Parsing Logic

struct DocumentParser {
    
    // MARK: Passport MRZ Parsing
    // Robust MRZ parser
    static func parsePassportMRZ(_ text: String) -> PassportData? {
        // 1. Clean and normalize
        let lines = text.components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: " ", with: "") }
            .filter { $0.count > 20 } // Relaxed length check
        
        // 2. Iterate to find potential MRZ lines
        for (index, line) in lines.enumerated() {
            // Find Line 1: P<...
            if line.starts(with: "P") && line.contains("<<") {
                
                // Try to find Line 2
                // Ideally it's the next line, but we can search forward a few lines just in case
                for i in 1...3 {
                    if index + i < lines.count {
                        let potentialLine2 = lines[index + i]
                        // Line 2 usually has digits at start (doc number) + birth date + expiry
                        // Check for common Line 2 chars: digits and <
                        // Let's rely on basic validation of length + content
                        
                        if potentialLine2.count > 20 && potentialLine2.contains("<") {
                            // Extract Data
                            return extractData(line1: line, line2: potentialLine2)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    static func extractData(line1: String, line2: String) -> PassportData? {
        // LINE 1: P<GBRSURNAME<<GIVEN<NAMES<<<<
        let namePart = line1.dropFirst(5) // Skip P<GBR (approx - country code len varies 3 chars)
        let nameComponents = namePart.components(separatedBy: "<<")
        
        let lastName = nameComponents.first?.replacingOccurrences(of: "<", with: " ") ?? ""
        var firstName = ""
        if nameComponents.count > 1 {
            firstName = nameComponents[1].components(separatedBy: "<").first ?? ""
        }
        
        // LINE 2: [DocNum 9] [Chk 1] [Nat 3] [DOB 6] [Chk 1] [Sex 1] [Exp 6] [Chk 1] ...
        // 1234567897GBR9001018M2801019<<<<<<<<<<<<<<02
        guard line2.count >= 28 else { return nil }
        
        let docNum = String(line2.prefix(9)).replacingOccurrences(of: "<", with: "")
        
        // Country can be extracted from Line 1 (chars 2-5) or Line 2 (chars 10-13)
        // Let's try Line 1 pos 2-5 (P<GBR) -> GBR
        let countryCode = String(line1.dropFirst(2).prefix(3))
        let nationality = countryName(from: countryCode)
        
        let dobString = String(line2.dropFirst(13).prefix(6))
        let expiryString = String(line2.dropFirst(21).prefix(6))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return PassportData(
            documentNumber: docNum,
            expiryDate: formatter.date(from: expiryString),
            birthDate: formatter.date(from: dobString),
            firstName: firstName,
            lastName: lastName,
            nationality: nationality
        )
    }
    
    // MARK: - Country Code Mapping
    static func countryName(from code: String) -> String {
        let code = code.replacingOccurrences(of: "<", with: "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let mapping: [String: String] = [
            "AFG": "Afghanistan", "ALB": "Albania", "DZA": "Algeria", "AND": "Andorra", "AGO": "Angola",
            "ATG": "Antigua and Barbuda", "ARG": "Argentina", "ARM": "Armenia", "AUS": "Australia",
            "AUT": "Austria", "AZE": "Azerbaijan", "BHS": "Bahamas", "BHR": "Bahrain", "BGD": "Bangladesh",
            "BRB": "Barbados", "BLR": "Belarus", "BEL": "Belgium", "BLZ": "Belize", "BEN": "Benin",
            "BTN": "Bhutan", "BOL": "Bolivia", "BIH": "Bosnia and Herzegovina", "BWA": "Botswana",
            "BRA": "Brazil", "BRN": "Brunei", "BGR": "Bulgaria", "BFA": "Burkina Faso", "BDI": "Burundi",
            "CPV": "Cabo Verde", "KHM": "Cambodia", "CMR": "Cameroon", "CAN": "Canada", "CAF": "Central African Republic",
            "TCD": "Chad", "CHL": "Chile", "CHN": "China", "COL": "Colombia", "COM": "Comoros",
            "COG": "Congo (Congo-Brazzaville)", "CRI": "Costa Rica", "HRV": "Croatia", "CUB": "Cuba",
            "CYP": "Cyprus", "CZE": "Czechia", "DNK": "Denmark", "DJI": "Djibouti", "DMA": "Dominica",
            "DOM": "Dominican Republic", "ECU": "Ecuador", "EGY": "Egypt", "SLV": "El Salvador",
            "GNQ": "Equatorial Guinea", "ERI": "Eritrea", "EST": "Estonia", "SWZ": "Eswatini",
            "ETH": "Ethiopia", "FJI": "Fiji", "FIN": "Finland", "FRA": "France", "GAB": "Gabon",
            "GMB": "Gambia", "GEO": "Georgia", "DEU": "Germany", "D": "Germany", "GHA": "Ghana",
            "GRC": "Greece", "GRD": "Grenada", "GTM": "Guatemala", "GIN": "Guinea", "GNB": "Guinea-Bissau",
            "GUY": "Guyana", "HTI": "Haiti", "HND": "Honduras", "HUN": "Hungary", "ISL": "Iceland",
            "IND": "India", "IDN": "Indonesia", "IRN": "Iran", "IRQ": "Iraq", "IRL": "Ireland",
            "ISR": "Israel", "ITA": "Italy", "JAM": "Jamaica", "JPN": "Japan", "JOR": "Jordan",
            "KAZ": "Kazakhstan", "KEN": "Kenya", "KIR": "Kiribati", "KWT": "Kuwait", "KGZ": "Kyrgyzstan",
            "LAO": "Laos", "LVA": "Latvia", "LBN": "Lebanon", "LSO": "Lesotho", "LBR": "Liberia",
            "LBY": "Libya", "LIE": "Liechtenstein", "LTU": "Lithuania", "LUX": "Luxembourg",
            "MDG": "Madagascar", "MWI": "Malawi", "MYS": "Malaysia", "MDV": "Maldives", "MLI": "Mali",
            "MLT": "Malta", "MHL": "Marshall Islands", "MRT": "Mauritania", "MUS": "Mauritius",
            "MEX": "Mexico", "FSM": "Micronesia", "MDA": "Moldova", "MCO": "Monaco", "MNG": "Mongolia",
            "MNE": "Montenegro", "MAR": "Morocco", "MOZ": "Mozambique", "MMR": "Myanmar",
            "NAM": "Namibia", "NRU": "Nauru", "NPL": "Nepal", "NLD": "Netherlands", "NZL": "New Zealand",
            "NIC": "Nicaragua", "NER": "Niger", "NGA": "Nigeria", "PRK": "North Korea",
            "MKD": "North Macedonia", "NOR": "Norway", "OMN": "Oman", "PAK": "Pakistan",
            "PLW": "Palau", "PSE": "Palestine State", "PAN": "Panama", "PNG": "Papua New Guinea",
            "PRY": "Paraguay", "PER": "Peru", "PHL": "Philippines", "POL": "Poland", "PRT": "Portugal",
            "QAT": "Qatar", "ROU": "Romania", "RUS": "Russia", "RWA": "Rwanda", "KNA": "Saint Kitts and Nevis",
            "LCA": "Saint Lucia", "VCT": "Saint Vincent and the Grenadines", "WSM": "Samoa",
            "SMR": "San Marino", "STP": "Sao Tome and Principe", "SAU": "Saudi Arabia", "SEN": "Senegal",
            "SRB": "Serbia", "SYC": "Seychelles", "SLE": "Sierra Leone", "SGP": "Singapore",
            "SVK": "Slovakia", "SVN": "Slovenia", "SLB": "Solomon Islands", "SOM": "Somalia",
            "ZAF": "South Africa", "KOR": "South Korea", "SSD": "South Sudan", "ESP": "Spain",
            "LKA": "Sri Lanka", "SDN": "Sudan", "SUR": "Suriname", "SWE": "Sweden", "CHE": "Switzerland",
            "SYR": "Syria", "TJK": "Tajikistan", "TZA": "Tanzania", "THA": "Thailand", "TLS": "Timor-Leste",
            "TGO": "Togo", "TON": "Tonga", "TTO": "Trinidad and Tobago", "TUN": "Tunisia", "TUR": "Turkey",
            "TKM": "Turkmenistan", "TUV": "Tuvalu", "UGA": "Uganda", "UKR": "Ukraine",
            "ARE": "United Arab Emirates", "GBR": "United Kingdom", "USA": "United States",
            "URY": "Uruguay", "UZB": "Uzbekistan", "VUT": "Vanuatu", "VEN": "Venezuela",
            "VNM": "Vietnam", "YEM": "Yemen", "ZMB": "Zambia", "ZWE": "Zimbabwe", "HKG": "Hong Kong"
        ]
        
        return mapping[code] ?? code
    }
    
    // MARK: Boarding Pass Parsing (BCBP)
    static func parseBoardingPass(_ payload: String) -> BoardingPassData? {
        // Format: M1LASTNAME/FIRSTNAME   EABCD123...
        // M1 is format code.
        guard payload.starts(with: "M") || payload.count > 20 else { return nil }
        
        // 1. Name: Between format code and next field
        // Usually fixed width or delimited.
        // Let's try to extract basic info using regex for typical patterns
        
        // PNR is usually 6-7 chars alphanumeric.
        // From/To are 3 letter codes.
        // Flight is Carrier + Number.
        
        // Example: M1WALK/ALEX           EABC123 LHRJFKBA 0117 100C010F00...
        
        // Very simplified extraction logic:
        
        // Name: Chars 2-21 (approx)
        let nameString = String(payload.dropFirst(2).prefix(20)).trimmingCharacters(in: .whitespaces)
        let nameParts = nameString.components(separatedBy: "/")
        let last = nameParts.first ?? ""
        let first = nameParts.count > 1 ? nameParts[1] : ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        
        // PNR: Often at position 23 (7 chars)
        let pnr = String(payload.dropFirst(23).prefix(7)).trimmingCharacters(in: .whitespaces)
        
        // Route: Origin (30), Dest (33)
        let origin = String(payload.dropFirst(30).prefix(3))
        let dest = String(payload.dropFirst(33).prefix(3))
        
        // Carrier (36-38), FlightNum (39-43)
        let carrier = String(payload.dropFirst(36).prefix(3)).trimmingCharacters(in: .whitespaces)
        let flightNum = String(payload.dropFirst(39).prefix(5)).trimmingCharacters(in: .whitespaces)
        
        // Julian Date (44-46) - Day of year
        let dayOfYear = Int(String(payload.dropFirst(44).prefix(3))) ?? 1
        
        // Seat (48-51)
        let seat = String(payload.dropFirst(48).prefix(4)).trimmingCharacters(in: .whitespaces)
        
        // Calc date
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.day = dayOfYear
        let flightDate = calendar.date(from: dateComponents)
        
        return BoardingPassData(
            name: fullName,
            pnr: pnr,
            origin: origin,
            destination: dest,
            carrier: carrier,
            flightNumber: flightNum,
            flightDate: flightDate,
            seat: seat,
            classCode: "Economy" // Default/Unknown
        )
    }
}

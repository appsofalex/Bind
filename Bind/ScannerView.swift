import SwiftUI
import Foundation
import VisionKit

// MARK: - Scanner View
struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedData: ScanResult?
    @Environment(\.dismiss) var dismiss
    
    // The types of items we want to scan
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    var dismissOnSuccess: Bool = true
    /// When true, the camera stops scanning and ignores further recognitions.
    var isPaused: Binding<Bool> = .constant(false)
    
    enum ScanMode {
        case passport
        case driversLicense
        case boardingPass
        case barcode
        case quickScan
    }
    
    let mode: ScanMode
    
    enum ScanHint: Equatable {
        case passportCandidate
    }
    
    /// Emits non-final hints (e.g. "this looks like a passport") so the caller can switch modes/UI.
    var onHint: ((ScanHint) -> Void)? = nil
    
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
        
        // 2. Example MRZ Code (Faded Grey) - Only shows in Landscape for Passport
        let exampleLabel = UILabel()
        exampleLabel.text = "P<GBRDOE<<JOHN<<<<<<<<<<<<<<<<<<<<\n1234567897GBR9001018M2801019<<<<<<"
        exampleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        exampleLabel.textAlignment = .center
        exampleLabel.numberOfLines = 2
        // Monospaced and larger to be clear
        exampleLabel.font = .monospacedSystemFont(ofSize: 18, weight: .semibold) 
        exampleLabel.translatesAutoresizingMaskIntoConstraints = false
        // Hide initially
        exampleLabel.alpha = 0
        exampleLabel.transform = .identity
        
        // 3. Determine Mode & Configure UI
        // Uses explicit mode passed in
        
        // Customize Text based on mode
        if mode == .passport {
            label.text = "Rotate phone to landscape & align the bottom 2 lines of passport"
            exampleLabel.text = "P<GBRDOE<<JOHN<<<<<<<<<<<<<<<<<<<<\n1234567897GBR9001018M2801019<<<<<<"
        } else if mode == .driversLicense {
            label.text = "Scan the back barcode (US) or front text (UK/EU)"
            exampleLabel.isHidden = true
        } else if mode == .boardingPass {
            label.text = "Align the boarding pass barcode to scan"
            exampleLabel.isHidden = true
        } else if mode == .quickScan {
            label.text = "Scan any card/document, QR code, or barcode"
            exampleLabel.isHidden = true
        } else {
            label.text = "Align any ticket barcode or QR code"
            exampleLabel.isHidden = true
        }
        
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
        context.coordinator.mode = mode // Pass mode to coordinator
        
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
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isPaused.wrappedValue {
            if uiViewController.isScanning {
                try? uiViewController.stopScanning()
            }
        } else {
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
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
        var mode: ScanMode = .passport
        private var hasCapturedResult: Bool = false
        
        // Drivers License: accumulate barcode + OCR into one result
        private var pendingDriversLicense: DriversLicenseData?
        private var finalizeDriversLicenseWorkItem: DispatchWorkItem?
        
        // Passport: accumulate MRZ lines before parsing
        private var pendingPassportText: String = ""
        private var finalizePassportWorkItem: DispatchWorkItem?
        private var hasSentPassportHint: Bool = false
        
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
            if let item = preferredItem(from: addedItems, allItems: allItems) {
                process(item)
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let item = preferredItem(from: updatedItems, allItems: allItems) {
                process(item)
            }
        }
        
        private func preferredItem(from changedItems: [RecognizedItem], allItems: [RecognizedItem]) -> RecognizedItem? {
            // In quick scan, prefer barcodes over text to reliably pick up boarding passes / tickets.
            if mode == .quickScan {
                if let b = changedItems.first(where: { if case .barcode = $0 { return true } else { return false } }) { return b }
                if let b = allItems.first(where: { if case .barcode = $0 { return true } else { return false } }) { return b }
                return changedItems.first
            }
            return changedItems.first
        }
        
        func process(_ item: RecognizedItem) {
            if hasCapturedResult { return }
            if parent.isPaused.wrappedValue { return }
            
            switch item {
            case .text(let text):
                // Mode-specific parsing
                switch mode {
                case .passport:
                    if let passportData = DocumentParser.parsePassportMRZ(text.transcript) {
                        hasCapturedResult = true
                        parent.scannedData = .passport(passportData)
                        if parent.dismissOnSuccess { parent.dismiss() }
                        return
                    }
                case .driversLicense, .quickScan:
                    // In quick scan, attempt Passport MRZ before other text parsing.
                    if mode == .quickScan {
                        if let passportData = DocumentParser.parsePassportMRZ(text.transcript) {
                            hasCapturedResult = true
                            parent.scannedData = .passport(passportData)
                            if parent.dismissOnSuccess { parent.dismiss() }
                            return
                        }
                        
                        // Accumulate MRZ-like text (often arrives fragmented across frames).
                        if text.transcript.contains("P<") || text.transcript.contains("<<") {
                            if !hasSentPassportHint {
                                hasSentPassportHint = true
                                DispatchQueue.main.async { [weak self] in
                                    self?.parent.onHint?(.passportCandidate)
                                }
                            }
                            handlePassportTextCandidate(text.transcript)
                        }
                    }
                    
                    if let dlData = DocumentParser.parseDriversLicenseText(text.transcript) {
                        handleDriversLicenseCandidate(dlData)
                        return
                    }
                case .boardingPass, .barcode:
                    break
                }
                
                // 2. Partial / Potential Match (Option 1 Enhancement)
                if mode == .passport, text.transcript.contains("P<") {
                    // Update UI to show detection
                    DispatchQueue.main.async {
                        self.instructionLabel?.text = "Hold Steady..."
                        self.instructionLabel?.textColor = .yellow
                        self.layoutInstructions() // Update layout for new text size
                    }
                } else {
                    // Reset if lost (optional, but good for feedback)
                    DispatchQueue.main.async {
                        let text: String
                        switch self.mode {
                        case .passport:
                            text = "Rotate phone to landscape & align the bottom 2 lines of passport"
                        case .driversLicense:
                            text = "Scan the back barcode (US) or front text (UK/EU)"
                        case .boardingPass:
                            text = "Align the boarding pass barcode to scan"
                        case .quickScan:
                            text = "Scan any card/document, QR code, or barcode"
                        case .barcode:
                            text = "Align any ticket barcode or QR code"
                        }
                        
                        if self.instructionLabel?.text != text {
                            self.instructionLabel?.text = text
                            self.instructionLabel?.textColor = .white
                            self.layoutInstructions()
                        }
                    }
                }
                
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    // Attempt to parse Drivers License first (US PDF417/AAMVA).
                    if (mode == .driversLicense || mode == .quickScan),
                       let dlData = DocumentParser.parseUSDriversLicenseAAMVA(payload) {
                        handleDriversLicenseCandidate(dlData)
                        return
                    }
                    
                    // Attempt to parse Boarding Pass
                    if let boardingPassData = DocumentParser.parseBoardingPass(payload) {
                        hasCapturedResult = true
                        parent.scannedData = .boardingPass(boardingPassData)
                        if parent.dismissOnSuccess { parent.dismiss() }
                    } else {
                        // It's a barcode but not a boarding pass, treat as generic
                        hasCapturedResult = true
                        parent.scannedData = .generic(payload)
                        if parent.dismissOnSuccess { parent.dismiss() }
                    }
                }
            default:
                break
            }
        }
        
        private func handleDriversLicenseCandidate(_ candidate: DriversLicenseData) {
            // Merge fields from multiple recognitions (barcode + OCR).
            pendingDriversLicense = mergeDriversLicenseData(base: pendingDriversLicense, incoming: candidate)
            
            // If we have enough, emit immediately; otherwise, wait briefly for the other source.
            if let merged = pendingDriversLicense, isDriversLicenseComplete(merged) {
                finalizeDriversLicense(merged)
                return
            }
            
            // Reset short debounce window on each new DL candidate.
            finalizeDriversLicenseWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                if let merged = self.pendingDriversLicense {
                    self.finalizeDriversLicense(merged)
                }
            }
            finalizeDriversLicenseWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
        }
        
        private func finalizeDriversLicense(_ data: DriversLicenseData) {
            if hasCapturedResult { return }
            hasCapturedResult = true
            finalizeDriversLicenseWorkItem?.cancel()
            finalizeDriversLicenseWorkItem = nil
            
            parent.scannedData = .driversLicense(data)
            if parent.dismissOnSuccess { parent.dismiss() }
        }
        
        private func isDriversLicenseComplete(_ data: DriversLicenseData) -> Bool {
            let hasLicenseNumber = !(data.licenseNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasFullName = !(data.fullName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasFirst = !(data.firstName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasLast = !(data.lastName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasName = hasFullName || (hasFirst && hasLast)
            return hasLicenseNumber && hasName
        }
        
        private func mergeDriversLicenseData(base: DriversLicenseData?, incoming: DriversLicenseData) -> DriversLicenseData {
            func pick(_ a: String?, _ b: String?) -> String? {
                let aa = a?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let aa, !aa.isEmpty { return aa }
                let bb = b?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let bb, !bb.isEmpty { return bb }
                return nil
            }
            
            guard let base else { return incoming }
            return DriversLicenseData(
                licenseNumber: pick(base.licenseNumber, incoming.licenseNumber),
                firstName: pick(base.firstName, incoming.firstName),
                lastName: pick(base.lastName, incoming.lastName),
                fullName: pick(base.fullName, incoming.fullName),
                birthDate: base.birthDate ?? incoming.birthDate,
                issueDate: base.issueDate ?? incoming.issueDate,
                expiryDate: base.expiryDate ?? incoming.expiryDate,
                address: pick(base.address, incoming.address),
                issuingCountry: pick(base.issuingCountry, incoming.issuingCountry)
            )
        }
        
        private func handlePassportTextCandidate(_ transcript: String) {
            // Keep a small rolling buffer of recent lines. We only need the MRZ, not full-page OCR.
            let cleaned = transcript
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .suffix(6)
                .joined(separator: "\n")
            
            if !cleaned.isEmpty {
                if pendingPassportText.isEmpty {
                    pendingPassportText = cleaned
                } else {
                    // Append and keep the tail to avoid unbounded growth.
                    pendingPassportText = (pendingPassportText + "\n" + cleaned)
                        .components(separatedBy: .newlines)
                        .suffix(12)
                        .joined(separator: "\n")
                }
            }
            
            // Try immediately on the aggregated buffer.
            if let passportData = DocumentParser.parsePassportMRZ(pendingPassportText) {
                hasCapturedResult = true
                finalizePassportWorkItem?.cancel()
                finalizePassportWorkItem = nil
                parent.scannedData = .passport(passportData)
                if parent.dismissOnSuccess { parent.dismiss() }
                return
            }
            
            // Otherwise debounce briefly to allow the second MRZ line to arrive.
            finalizePassportWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                if self.hasCapturedResult { return }
                if let passportData = DocumentParser.parsePassportMRZ(self.pendingPassportText) {
                    self.hasCapturedResult = true
                    self.parent.scannedData = .passport(passportData)
                    if self.parent.dismissOnSuccess { self.parent.dismiss() }
                }
            }
            finalizePassportWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
        }
    }
}

// MARK: - Data Models

enum ScanResult: Equatable {
    case passport(PassportData)
    case driversLicense(DriversLicenseData)
    case boardingPass(BoardingPassData)
    case generic(String)
}

struct PassportData: Equatable {
    let documentNumber: String
    let expiryDate: Date?
    let birthDate: Date?
    let firstName: String
    let lastName: String
    let nationality: String
}

struct DriversLicenseData: Equatable {
    let licenseNumber: String?
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let birthDate: Date?
    let issueDate: Date?
    let expiryDate: Date?
    let address: String?
    /// Intended for mapping to `DocumentFormView`'s "Issuing Country" picker.
    let issuingCountry: String?
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
    /// Raw barcode payload (PDF417/Aztec/etc.) for rendering on the card.
    let rawPayload: String?
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
        var first = nameParts.count > 1 ? nameParts[1] : ""
        
        // Cleanup Titles (MR, MRS, MS, MISS, DR, MSTR) from end of First Name
        let titles = ["MSTR", "MISS", "MRS", "MR", "MS", "DR", "PROF"]
        for title in titles {
            if first.hasSuffix(title) {
                // Ensure we don't accidentally strip names that just end in these letters
                // usually titles are appended without space (e.g. JOHNMR)
                // We'll strip it if the remaining name is at least 2 chars long
                let newLength = first.count - title.count
                if newLength >= 2 {
                    first = String(first.prefix(newLength))
                    break // Only remove one title
                }
            }
        }
        
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        
        // PNR: Often at position 23 (7 chars)
        let pnr = String(payload.dropFirst(23).prefix(7)).trimmingCharacters(in: .whitespaces)
        
        // Route: Origin (30), Dest (33)
        let origin = String(payload.dropFirst(30).prefix(3))
        let dest = String(payload.dropFirst(33).prefix(3))
        
        // Carrier (36-38), FlightNum (39-43)
        let carrier = String(payload.dropFirst(36).prefix(3)).trimmingCharacters(in: .whitespaces)
        let rawFlightNum = String(payload.dropFirst(39).prefix(5)).trimmingCharacters(in: .whitespaces)
        
        // Format Flight Number: Carrier + Number (stripping leading zeros)
        // e.g. "00206" -> "206", combined with "EK" -> "EK206"
        let flightNum: String
        if let number = Int(rawFlightNum) {
             flightNum = "\(carrier)\(number)"
        } else {
             flightNum = "\(carrier)\(rawFlightNum)"
        }
        
        // Julian Date (44-46) - Day of year
        let dayOfYear = Int(String(payload.dropFirst(44).prefix(3))) ?? 1
        
        // Compartment Code (Class) - Position 47 (1 char)
        // Standard BCBP often has it here.
        let classCode = String(payload.dropFirst(47).prefix(1))
        
        // Seat (48-51)
        var seat = String(payload.dropFirst(48).prefix(4)).trimmingCharacters(in: .whitespaces)
        // Strip leading zeros (e.g., "09D" -> "9D", "048C" -> "48C")
        if seat.hasPrefix("0") {
            seat = String(seat.drop(while: { $0 == "0" }))
        }
        
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
            classCode: classCode,
            rawPayload: payload
        )
    }

    // MARK: - Driver's License Parsing
    /// Attempts to parse a US/Canada-style PDF417 barcode payload (AAMVA). Returns nil if it doesn't look like AAMVA.
    static func parseUSDriversLicenseAAMVA(_ payload: String) -> DriversLicenseData? {
        // Typical AAMVA payloads contain "ANSI " or "AAMVA" and element IDs like "DAQ", "DBB", "DBA".
        let upper = payload.uppercased()
        guard upper.contains("AAMVA") || upper.contains("ANSI") || upper.contains("DL") else { return nil }
        guard upper.contains("DAQ") || upper.contains("DBB") || upper.contains("DBA") || upper.contains("DCS") else { return nil }
        
        let fields = aamvaFieldMap(from: payload)
        
        let licenseNumber = fields["DAQ"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let firstName = fields["DAC"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = fields["DCS"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let fullName: String?
        if let f = firstName, let l = lastName, !f.isEmpty, !l.isEmpty {
            fullName = "\(f) \(l)"
        } else if let daa = fields["DAA"]?.trimmingCharacters(in: .whitespacesAndNewlines), !daa.isEmpty {
            fullName = daa
        } else {
            fullName = nil
        }
        
        let birthDate = parseDLDate(fields["DBB"])
        let issueDate = parseDLDate(fields["DBD"])
        let expiryDate = parseDLDate(fields["DBA"])
        
        // Address components (best effort)
        let street = fields["DAG"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = fields["DAI"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let state = fields["DAJ"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let zip = fields["DAK"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var addressParts: [String] = []
        if let street, !street.isEmpty { addressParts.append(street) }
        var cityLine: [String] = []
        if let city, !city.isEmpty { cityLine.append(city) }
        if let state, !state.isEmpty { cityLine.append(state) }
        if let zip, !zip.isEmpty { cityLine.append(zip) }
        if !cityLine.isEmpty { addressParts.append(cityLine.joined(separator: " ")) }
        let address = addressParts.isEmpty ? nil : addressParts.joined(separator: "\n")
        
        // For US/CA AAMVA we can safely set issuing country to United States (or Canada if we detect it).
        let issuingCountry: String? = (upper.contains("CAN") || upper.contains("CANADA")) ? "Canada" : "United States"
        
        // Must have at least a license number or a name to be considered a success.
        if (licenseNumber?.isEmpty ?? true) && (fullName?.isEmpty ?? true) { return nil }
        
        return DriversLicenseData(
            licenseNumber: licenseNumber,
            firstName: firstName,
            lastName: lastName,
            fullName: fullName,
            birthDate: birthDate,
            issueDate: issueDate,
            expiryDate: expiryDate,
            address: address,
            issuingCountry: issuingCountry
        )
    }
    
    /// Best-effort OCR parsing for UK/EU (and other) licenses from recognized text.
    static func parseDriversLicenseText(_ text: String) -> DriversLicenseData? {
        let normalized = normalizeOCRText(text)
        let upper = normalized.uppercased()
        
        // UK photocard: look for "DRIVING LICENCE" and the driver number pattern.
        let looksUK = upper.contains("DRIVING LICENCE") || upper.contains("DRIVING LICENSE") || upper.contains("DVLA") || upper.contains("UNITED KINGDOM")
        let ukNumber = extractUKDriverNumber(fromUpperText: upper)
        
        // EU: look for multiple-language "DRIVING LICENCE" and common field markers (1.,2.,3.,4A,4B,5,8).
        let looksEU = upper.contains("PERMIS") || upper.contains("FAHRERLAUBNIS") || upper.contains("PATENTE") || upper.contains("PERMESSO") || upper.contains("RIJBEWIJS") || upper.contains("FÜHRERSCHEIN")
        let euNumber = extractLabeledNumber(fromUpperText: upper)
        
        let issuingCountry: String? = looksUK ? "United Kingdom" : (looksEU ? nil : nil)
        
        // Dates (best effort)
        let birthDate = extractDate(fromUpperText: upper, hints: ["DOB", "BIRTH", "DATE OF BIRTH", "3", "3.", "BORN"])
        let issueDate = extractDate(fromUpperText: upper, hints: ["ISSUE", "ISSUED", "4A", "4A.", "DATE OF ISSUE"])
        let expiryDate = extractDate(fromUpperText: upper, hints: ["EXP", "EXPIRES", "VALID", "4B", "4B.", "VALID UNTIL", "DATE OF EXPIRY", "DATE OF EXPIRATION"])
        
        // Name heuristics:
        // - If we see "1." and "2." (EU format), prefer those.
        // - Otherwise fall back to a "SURNAME" / "GIVEN" style.
        let (firstName, lastName, fullName) = extractName(fromUpperText: upper)
        
        // Address heuristics (often labeled 8 or "ADDRESS")
        let address = extractAddress(fromUpperText: upper)
        
        // License number preference: UK pattern, then labeled number, else nil.
        let licenseNumber = (ukNumber ?? euNumber)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If we didn’t find anything distinguishing, return nil to avoid false positives.
        let hasSignal = (licenseNumber?.isEmpty == false) || (fullName?.isEmpty == false) || birthDate != nil || expiryDate != nil
        guard hasSignal else { return nil }
        
        return DriversLicenseData(
            licenseNumber: licenseNumber,
            firstName: firstName,
            lastName: lastName,
            fullName: fullName,
            birthDate: birthDate,
            issueDate: issueDate,
            expiryDate: expiryDate,
            address: address,
            issuingCountry: issuingCountry
        )
    }
    
    private static func aamvaFieldMap(from payload: String) -> [String: String] {
        // Split on common record separators and newlines.
        let separators = CharacterSet(charactersIn: "\u{001E}\u{001F}\r\n")
        let rawParts = payload.components(separatedBy: separators)
        var map: [String: String] = [:]
        
        for part in rawParts {
            guard part.count >= 3 else { continue }
            let key = String(part.prefix(3)).uppercased()
            let value = String(part.dropFirst(3))
            
            // Only accept likely AAMVA element IDs (Dxx).
            if key.count == 3, key.hasPrefix("D"), key.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.union(.decimalDigits).contains($0) }) {
                if map[key] == nil {
                    map[key] = value
                }
            }
        }
        
        return map
    }
    
    private static func parseDLDate(_ raw: String?) -> Date? {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        // Strip non-digits
        s = s.filter(\.isNumber)
        guard s.count == 8 else { return nil }
        
        // Try YYYYMMDD then MMDDYYYY.
        let f1 = DateFormatter()
        f1.timeZone = TimeZone(secondsFromGMT: 0)
        f1.dateFormat = "yyyyMMdd"
        if let d = f1.date(from: s) { return d }
        
        let f2 = DateFormatter()
        f2.timeZone = TimeZone(secondsFromGMT: 0)
        f2.dateFormat = "MMddyyyy"
        return f2.date(from: s)
    }
    
    private static func normalizeOCRText(_ text: String) -> String {
        // Keep line structure but normalize common OCR confusions.
        return text
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "•", with: " ")
    }
    
    private static func extractUKDriverNumber(fromUpperText upper: String) -> String? {
        // UK driver number is typically 16+ chars: 5 letters + 6 digits + 2 letters + 3 digits (often)
        // We use a loose pattern to reduce false negatives with OCR errors.
        let pattern = #"\b[A-Z]{5}[0-9]{6}[A-Z0-9]{5,8}\b"#
        return firstRegexMatch(in: upper, pattern: pattern)
    }
    
    private static func extractLabeledNumber(fromUpperText upper: String) -> String? {
        // EU often labels the license number as "5." or just "5" on the card.
        // Try "5" label, "LICENCE NO", "LICENSE NO", "NUMERO", etc.
        let patterns = [
            #"(?:\b5\.?\s*)([A-Z0-9]{6,})"#,
            #"(?:LICEN[CS]E\s*NO\.?\s*)([A-Z0-9]{6,})"#,
            #"(?:DOCUMENT\s*NO\.?\s*)([A-Z0-9]{6,})"#,
            #"(?:NUM[EÉ]RO\s*DE\s*PERMIS\s*:?\s*)([A-Z0-9]{6,})"#
        ]
        for p in patterns {
            if let m = firstRegexCapture(in: upper, pattern: p, group: 1) { return m }
        }
        return nil
    }
    
    private static func extractDate(fromUpperText upper: String, hints: [String]) -> Date? {
        // Find lines containing any hint, then parse the first date-like token.
        let lines = upper.components(separatedBy: .newlines)
        let candidateLines = lines.filter { line in
            hints.contains(where: { h in line.contains(h) })
        }
        
        for line in candidateLines {
            if let d = parseDateFromLine(line) { return d }
        }
        
        // Fallback: any date in the entire text (avoid overly eager).
        return nil
    }
    
    private static func parseDateFromLine(_ line: String) -> Date? {
        // Support common formats: DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD.
        let patterns = [
            #"\b(\d{2})[./-](\d{2})[./-](\d{4})\b"#, // DMY
            #"\b(\d{4})[./-](\d{2})[./-](\d{2})\b"#  // YMD
        ]
        
        if let m = regexGroups(in: line, pattern: patterns[0], groupCount: 3) {
            let dd = m[0], mm = m[1], yyyy = m[2]
            return parseDateWithFormats("\(dd)/\(mm)/\(yyyy)", formats: ["dd/MM/yyyy"])
        }
        if let m = regexGroups(in: line, pattern: patterns[1], groupCount: 3) {
            let yyyy = m[0], mm = m[1], dd = m[2]
            return parseDateWithFormats("\(yyyy)-\(mm)-\(dd)", formats: ["yyyy-MM-dd"])
        }
        
        // Sometimes OCR yields 8-digit date without separators.
        if let raw = firstRegexMatch(in: line, pattern: #"\b\d{8}\b"#) {
            return parseDLDate(raw)
        }
        
        return nil
    }
    
    private static func parseDateWithFormats(_ str: String, formats: [String]) -> Date? {
        for format in formats {
            let f = DateFormatter()
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.dateFormat = format
            if let d = f.date(from: str) { return d }
        }
        return nil
    }
    
    private static func extractName(fromUpperText upper: String) -> (String?, String?, String?) {
        // EU format often uses:
        // 1. Surname
        // 2. Given name(s)
        let surname = firstRegexCapture(in: upper, pattern: #"(?:\b1\.?\s*)([A-Z][A-Z\s'\-]{1,})"#, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = firstRegexCapture(in: upper, pattern: #"(?:\b2\.?\s*)([A-Z][A-Z\s'\-]{1,})"#, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let s = surname, !s.isEmpty, let g = given, !g.isEmpty {
            return (g, s, "\(g) \(s)")
        }
        
        // Generic labels
        let s2 = firstRegexCapture(in: upper, pattern: #"(?:SURNAME|LAST\s*NAME)\s*:?\s*([A-Z][A-Z\s'\-]{1,})"#, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let g2 = firstRegexCapture(in: upper, pattern: #"(?:GIVEN\s*NAMES?|FIRST\s*NAME)\s*:?\s*([A-Z][A-Z\s'\-]{1,})"#, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let s2, !s2.isEmpty, let g2, !g2.isEmpty {
            return (g2, s2, "\(g2) \(s2)")
        }
        
        return (nil, nil, nil)
    }
    
    private static func extractAddress(fromUpperText upper: String) -> String? {
        // Look for a labeled ADDRESS block.
        if let addr = firstRegexCapture(in: upper, pattern: #"(?:ADDRESS|ADDR)\s*:?\s*([A-Z0-9 ,.'\-\n]{10,})"#, group: 1) {
            return addr.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // EU sometimes labels as "8." address.
        if let addr = firstRegexCapture(in: upper, pattern: #"(?:\b8\.?\s*)([A-Z0-9 ,.'\-\n]{10,})"#, group: 1) {
            return addr.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    private static func firstRegexMatch(in text: String, pattern: String) -> String? {
        guard let r = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = r.firstMatch(in: text, options: [], range: range) else { return nil }
        guard let rr = Range(m.range, in: text) else { return nil }
        return String(text[rr])
    }
    
    private static func firstRegexCapture(in text: String, pattern: String, group: Int) -> String? {
        guard let r = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = r.firstMatch(in: text, options: [], range: range) else { return nil }
        guard group < m.numberOfRanges else { return nil }
        guard let rr = Range(m.range(at: group), in: text) else { return nil }
        return String(text[rr])
    }
    
    private static func regexGroups(in text: String, pattern: String, groupCount: Int) -> [String]? {
        guard let r = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = r.firstMatch(in: text, options: [], range: range) else { return nil }
        guard m.numberOfRanges >= groupCount + 1 else { return nil }
        var out: [String] = []
        for i in 1...groupCount {
            guard let rr = Range(m.range(at: i), in: text) else { return nil }
            out.append(String(text[rr]))
        }
        return out
    }
}


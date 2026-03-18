import SwiftUI
import VisionKit
import Vision
import UIKit

// MARK: - Quick Scan Add Request (type + scan result for Add form)
private struct QuickScanAddRequest: Identifiable {
    let id = UUID()
    let type: TravelDocument.DocumentType
    let scanResult: ScanResult
}

// MARK: - Quick Scan View
struct QuickScanView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    @State private var scannedData: ScanResult?
    @State private var addRequest: QuickScanAddRequest?
    @State private var showScannerUnavailableAlert = false
    @State private var showCameraPermissionAlert = false
    @State private var isScannerPaused = false
    @State private var scannerMode: ScannerView.ScanMode = .quickScan
    
    private var recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> {
        switch scannerMode {
        case .passport:
            // Match "Scan Passport" behavior: text-only MRZ focus.
            return [.text(textContentType: nil)]
        case .quickScan:
            // Prefer QR/barcodes for tickets/boarding passes; keep text enabled so we can
            // detect and auto-switch into Passport mode and also support DL front-text.
            return [
                .barcode(symbologies: [.qr, .aztec, .pdf417, .code128, .code39, .ean8, .ean13, .upce]),
                .text(textContentType: nil)
            ]
        default:
            return [
                .barcode(symbologies: [.qr, .aztec, .pdf417, .code128, .code39, .ean8, .ean13, .upce]),
                .text(textContentType: nil)
            ]
        }
    }
    
    var body: some View {
        Group {
            if ScannerView.isSupported {
                ScannerView(
                    scannedData: $scannedData,
                    recognizedDataTypes: recognizedDataTypes,
                    dismissOnSuccess: false,
                    isPaused: $isScannerPaused,
                    mode: scannerMode,
                    onHint: { hint in
                        // When the camera starts recognizing passport MRZ patterns,
                        // switch into the dedicated Passport scanner UI/logic.
                        if hint == .passportCandidate, scannerMode == .quickScan {
                            scannerMode = .passport
                        }
                    }
                )
                // Force scanner recreation when switching modes so the overlay + mode-specific
                // behavior matches "Scan Passport" exactly.
                .id(scannerMode)
                .ignoresSafeArea()
            }
        }
        .onChange(of: scannedData) { _, result in
            guard let result = result else { return }
            // Freeze the camera the moment we have a result so the sheet can't flap.
            isScannerPaused = true
            switch result {
            case .passport:
                addRequest = QuickScanAddRequest(type: .passport, scanResult: result)
            case .driversLicense:
                addRequest = QuickScanAddRequest(type: .driversLicense, scanResult: result)
            case .boardingPass:
                addRequest = QuickScanAddRequest(type: .boardingPass, scanResult: result)
            case .generic(let payload):
                // Default generic barcodes/QRs to an Event card (common "ticket" use-case).
                addRequest = QuickScanAddRequest(type: .event, scanResult: .generic(payload))
            }
        }
        .sheet(item: $addRequest, onDismiss: { addRequest = nil }) { request in
            DocumentFormView(type: request.type, initialScanResult: request.scanResult) { newDoc in
                documents.append(newDoc)
                dismiss()
            }
        }
        .onAppear {
            scannerMode = .quickScan
            if !ScannerView.isSupported {
                showScannerUnavailableAlert = true
            } else {
                CameraPermission.ensureAuthorized { status in
                    switch status {
                    case .granted:
                        break
                    case .noCamera:
                        showScannerUnavailableAlert = true
                    case .denied, .restricted:
                        showCameraPermissionAlert = true
                    }
                }
            }
        }
        .alert("Scanner Unavailable", isPresented: $showScannerUnavailableAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your device does not support scanning. This feature requires a camera and is not available on simulators.")
        }
        .alert("Camera Access Needed", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Bind needs access to your camera to quickly scan documents. You can enable this in Settings.")
        }
    }
}

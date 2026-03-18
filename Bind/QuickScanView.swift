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

// MARK: - Generic Barcode Type Picker Options
private let genericBarcodeTypes: [(TravelDocument.DocumentType, String)] = [
    (.rewardsCard, "Rewards Card"),
    (.insurance, "Insurance"),
    (.event, "Event Ticket"),
    (.studentID, "Student ID"),
    (.prescription, "Prescription"),
    (.nationalInsurance, "National Insurance"),
    (.visa, "Visa"),
    (.idCard, "ID Card"),
]

// MARK: - Quick Scan View
struct QuickScanView: View {
    @Binding var documents: [TravelDocument]
    @Environment(\.dismiss) var dismiss
    
    @State private var scannedData: ScanResult?
    @State private var addRequest: QuickScanAddRequest?
    @State private var pendingGenericPayload: String?
    @State private var showScannerUnavailableAlert = false
    @State private var showCameraPermissionAlert = false
    
    private static let quickScanDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
        .text(textContentType: nil),
        .barcode(symbologies: [.qr, .aztec, .pdf417, .code128, .code39, .ean8, .ean13, .upce])
    ]
    
    var body: some View {
        Group {
            if ScannerView.isSupported {
                ScannerView(
                    scannedData: $scannedData,
                    recognizedDataTypes: Self.quickScanDataTypes,
                    dismissOnSuccess: false,
                    mode: .quickScan
                )
                .ignoresSafeArea()
            }
        }
        .onChange(of: scannedData) { _, result in
            guard let result = result else { return }
            switch result {
            case .passport:
                addRequest = QuickScanAddRequest(type: .passport, scanResult: result)
            case .driversLicense:
                addRequest = QuickScanAddRequest(type: .driversLicense, scanResult: result)
            case .boardingPass:
                addRequest = QuickScanAddRequest(type: .boardingPass, scanResult: result)
            case .generic(let payload):
                pendingGenericPayload = payload
            }
        }
        .sheet(item: $addRequest, onDismiss: { addRequest = nil }) { request in
            DocumentFormView(type: request.type, initialScanResult: request.scanResult) { newDoc in
                documents.append(newDoc)
                dismiss()
            }
        }
        .sheet(isPresented: Binding(
            get: { pendingGenericPayload != nil },
            set: { if !$0 { pendingGenericPayload = nil } }
        )) {
            if let payload = pendingGenericPayload {
                GenericBarcodeTypePickerView(payload: payload) { selectedType in
                    addRequest = QuickScanAddRequest(type: selectedType, scanResult: .generic(payload))
                    pendingGenericPayload = nil
                } onCancel: {
                    pendingGenericPayload = nil
                }
            }
        }
        .onAppear {
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

// MARK: - Generic Barcode Type Picker
private struct GenericBarcodeTypePickerView: View {
    let payload: String
    let onSelect: (TravelDocument.DocumentType) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(payload)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(2)
                        .truncationMode(.tail)
                } header: {
                    Text("Scanned")
                }
                
                Section {
                    ForEach(genericBarcodeTypes, id: \.0) { type, label in
                        Button(action: {
                            onSelect(type)
                        }) {
                            HStack {
                                Image(systemName: iconForType(type))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 28)
                                Text(label)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } header: {
                    Text("What type of card?")
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForType(_ type: TravelDocument.DocumentType) -> String {
        switch type {
        case .rewardsCard: return "star.fill"
        case .insurance: return "cross.case.fill"
        case .event: return "ticket.fill"
        case .studentID: return "graduationcap.fill"
        case .prescription: return "pills.fill"
        case .nationalInsurance: return "number.square.fill"
        case .visa: return "checkmark.seal.fill"
        case .idCard: return "person.text.rectangle.fill"
        default: return "doc.fill"
        }
    }
}

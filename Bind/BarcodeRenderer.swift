import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Barcode kind for rendering
enum BarcodeKind {
    case code128  // 1D, alphanumeric; good for loyalty/ticket numbers
    case qr       // 2D; good for boarding passes / long payloads
}

// MARK: - Barcode image generation
enum BarcodeRenderer {

    /// Renders a scannable barcode or QR image from a string payload.
    /// Returns nil if the payload is empty, unsupported, or generation fails (caller should show placeholder).
    static func makeBarcodeImage(from payload: String, kind: BarcodeKind = .code128) -> Image? {
        guard !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let context = CIContext()
        switch kind {
        case .code128:
            return makeCode128Image(payload: payload, context: context)
        case .qr:
            return makeQRImage(payload: payload, context: context)
        }
    }

    private static func makeCode128Image(payload: String, context: CIContext) -> Image? {
        let data = payload.data(using: .ascii) ?? payload.data(using: .utf8)
        guard let data = data else { return nil }
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = data
        filter.quietSpace = 5
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 4, y: 4))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }

    private static func makeQRImage(payload: String, context: CIContext) -> Image? {
        guard let data = payload.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale: CGFloat = 8
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}

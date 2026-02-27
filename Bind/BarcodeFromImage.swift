import UIKit
import Vision

/// Extracts a barcode payload string from a still image (e.g. screenshot of a rewards card or ticket).
/// Runs on a background queue; call from async context.
enum BarcodeFromImage {

    /// Detects barcodes in the image and returns the best payload (longest or first with string value).
    /// Returns nil if no barcode is found or image is invalid. Runs off the main thread.
    static func extractBarcodePayload(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return await Task.detached {
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr, .aztec, .pdf417, .code128, .code39, .ean8, .ean13, .upce]
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return nil
            }
            guard let results = request.results as? [VNBarcodeObservation] else { return nil }
            let payloads = results.compactMap { $0.payloadStringValue }.filter { !$0.isEmpty }
            // Multiple barcodes: prefer longest payload (typically the main ticket/loyalty code).
            return payloads.max(by: { $0.count < $1.count })
        }.value
    }
}

extension UIImage {
    /// CGImage orientation for Vision, derived from imageOrientation.
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

import AVFoundation
import Foundation

/// Lightweight helper for checking and requesting camera access.
enum CameraPermissionStatus {
    case granted
    case denied
    case restricted
    case noCamera
}

struct CameraPermission {
    static func ensureAuthorized(completion: @escaping (CameraPermissionStatus) -> Void) {
        guard AVCaptureDevice.default(for: .video) != nil else {
            completion(.noCamera)
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            completion(.granted)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? .granted : .denied)
                }
            }
        case .denied:
            completion(.denied)
        case .restricted:
            completion(.restricted)
        @unknown default:
            completion(.denied)
        }
    }
}


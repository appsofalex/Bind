import SwiftUI
import UIKit

/// Presents the native camera for document capture.
/// Captured image is returned for cropping via ImageCropperView.
struct CameraCaptureView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
}

/// Container that presents the native camera (Use Photo / Retake), then parent shows Adjust & Crop on a separate sheet.
struct CameraCaptureWithOverlayView: View {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        CameraCaptureView(
            onImageCaptured: onImageCaptured,
            onCancel: onCancel
        )
        .ignoresSafeArea()
    }
}

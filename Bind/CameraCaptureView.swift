import SwiftUI
import UIKit

/// Card aspect ratio (ID-1 standard, matches ImageCropperView)
private let cardAspectRatio: CGFloat = 1.586

/// Shape with a rectangular hole for the card cutout (even-odd fill)
private struct CardCutoutShape: Shape {
    let holeRect: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        path.addPath(RoundedRectangle(cornerRadius: 12).path(in: holeRect))
        return path
    }
}

/// Presents the native camera with a card-sized overlay to help users frame their document.
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

/// Container that presents the camera with a card-shaped overlay. The overlay shows a subtle
/// border where the user should position their card for optimal capture.
struct CameraCaptureWithOverlayView: View {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            CameraCaptureView(
                onImageCaptured: onImageCaptured,
                onCancel: onCancel
            )
            .ignoresSafeArea()
            
            CameraOverlaySwiftUI()
                .allowsHitTesting(false)
        }
    }
}

/// SwiftUI overlay with card-shaped cutout and subtle border
private struct CameraOverlaySwiftUI: View {
    var body: some View {
        GeometryReader { geo in
            let padding: CGFloat = 24
            let availableWidth = geo.size.width - (padding * 2)
            let frameHeight = availableWidth / cardAspectRatio
            let frameWidth = availableWidth
            let originX = padding
            let originY = (geo.size.height - frameHeight) / 2
            let holeRect = CGRect(x: originX, y: originY, width: frameWidth, height: frameHeight)
            
            ZStack {
                // Semi-transparent mask with card-shaped cutout
                Color.black.opacity(0.5)
                    .mask(CardCutoutShape(holeRect: holeRect).fill(style: FillStyle(eoFill: true)))
                
                // Card frame border (subtle white stroke)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: frameWidth, height: frameHeight)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

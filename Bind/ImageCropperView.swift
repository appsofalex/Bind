import SwiftUI

/// Used so the cropper can read container size outside the GeometryReader (toolbar appears immediately).
private struct ContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

/// Extension to normalize a UIImage's orientation to "up".
/// This is crucial because `CGImage.cropping` does not respect EXIF orientation data.
fileprivate extension UIImage {
    func orientedUp() -> UIImage {
        // If the image is already upright, no changes are needed.
        guard imageOrientation != .up else { return self }
        
        // Create a graphics context to redraw the image.
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        // The `draw` method correctly handles the orientation.
        draw(in: CGRect(origin: .zero, size: size))
        
        // Return the new, normalized image.
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

/// A view that allows a user to pan and zoom an image to crop it to a specific aspect ratio.
struct ImageCropperView: View {
    let image: UIImage
    var onCrop: (UIImage) -> Void
    /// When provided, a "Retake" button is shown so the user can return to the camera.
    var onRetake: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss

    // State for pan and zoom gestures
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    /// Stored so toolbar (outside GeometryReader) can use it and layout is stable from first frame.
    @State private var containerSize: CGSize = .zero
    
    // The aspect ratio for a standard ID-1 card (e.g., credit cards, driver's licenses).
    private let cardAspectRatio: CGFloat = 1.586

    init(image: UIImage, onCrop: @escaping (UIImage) -> Void, onRetake: (() -> Void)? = nil) {
        // Normalize the image's orientation upon initialization.
        self.image = image.orientedUp()
        self.onCrop = onCrop
        self.onRetake = onRetake
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    let cropFrame = calculateCropFrame(in: geometry.size)
                    ZStack {
                        // The interactive image that can be panned and zoomed
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        self.offset = CGSize(
                                            width: value.translation.width + self.lastOffset.width,
                                            height: value.translation.height + self.lastOffset.height
                                        )
                                    }
                                    .onEnded { _ in self.lastOffset = self.offset }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / self.lastScale
                                        self.scale *= delta
                                        self.lastScale = value
                                    }
                                    .onEnded { _ in self.lastScale = 1.0 }
                            )
                        
                        // A semi-transparent mask with a card-shaped cutout
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .mask(HoleShape(rect: cropFrame).fill(style: FillStyle(eoFill: true)))
                            .allowsHitTesting(false)
                        
                        // A white border to clearly define the cropping frame
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropFrame.width, height: cropFrame.height)
                            .position(x: cropFrame.midX, y: cropFrame.midY)
                            .allowsHitTesting(false)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .preference(key: ContainerSizeKey.self, value: geometry.size)
                }
                .onPreferenceChange(ContainerSizeKey.self) { containerSize = $0 }

                // Retake at bottom center (only when in camera flow)
                if onRetake != nil {
                    Button(action: { onRetake?() }) {
                        Text("Retake")
                            .font(.body.weight(.medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Adjust and Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crop") {
                        guard containerSize != .zero else { return }
                        cropImage(in: containerSize)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    /// Calculates the CGRect for the cropping frame based on the container's size.
    private func calculateCropFrame(in containerSize: CGSize) -> CGRect {
        let padding: CGFloat = 20
        let availableWidth = containerSize.width - (padding * 2)
        let frameHeight = availableWidth / cardAspectRatio
        let frameWidth = availableWidth
        
        let originX = padding
        let originY = (containerSize.height - frameHeight) / 2
        
        return CGRect(x: originX, y: originY, width: frameWidth, height: frameHeight)
    }
    
    /// A helper shape used to cut a hole in the overlay mask.
    private struct HoleShape: Shape {
        let rect: CGRect
        func path(in frame: CGRect) -> Path {
            var path = Rectangle().path(in: frame)
            path.addPath(RoundedRectangle(cornerRadius: 12).path(in: rect))
            return path
        }
    }

    /// Performs the image crop based on the user's pan and zoom adjustments.
    private func cropImage(in containerSize: CGSize) {
        let cropRect = calculateCropFrame(in: containerSize)
        
        // Convert the SwiftUI view coordinates and scale to the UIImage's pixel coordinates.
        let imageSize = image.size
        let viewAspectRatio = containerSize.width / containerSize.height
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var scaledImageSize: CGSize
        if imageAspectRatio > viewAspectRatio {
            scaledImageSize = CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
        } else {
            scaledImageSize = CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
        }
        
        let viewToImageRatio = image.size.width / (scaledImageSize.width * scale)

        let imageOriginInView = CGPoint(
            x: (containerSize.width - scaledImageSize.width * scale) / 2 + offset.width,
            y: (containerSize.height - scaledImageSize.height * scale) / 2 + offset.height
        )
        
        let cropOriginInImage = CGPoint(
            x: (cropRect.origin.x - imageOriginInView.x) * viewToImageRatio,
            y: (cropRect.origin.y - imageOriginInView.y) * viewToImageRatio
        )
        
        let cropSizeInImage = CGSize(
            width: cropRect.width * viewToImageRatio,
            height: cropRect.height * viewToImageRatio
        )

        let finalCropRect = CGRect(origin: cropOriginInImage, size: cropSizeInImage)

        // Use Core Graphics to perform the crop.
        if let cgImage = image.cgImage?.cropping(to: finalCropRect) {
            let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            onCrop(croppedImage)
        }
    }
}

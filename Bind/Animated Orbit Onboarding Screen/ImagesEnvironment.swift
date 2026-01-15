import SwiftUI

private struct ImagesEnvironmentKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension EnvironmentValues {
    var images: [String] {
        get { self[ImagesEnvironmentKey.self] }
        set { self[ImagesEnvironmentKey.self] = newValue }
    }
}

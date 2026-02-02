import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    
    var id: String { self.rawValue }
}

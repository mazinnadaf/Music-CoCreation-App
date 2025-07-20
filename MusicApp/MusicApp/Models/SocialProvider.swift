import SwiftUI

enum SocialProvider: String, CaseIterable {
    case google = "Google"
    case apple = "Apple"
    case tiktok = "TikTok"
    
    var icon: String {
        switch self {
        case .google: return "globe"
        case .apple: return "applelogo"
        case .tiktok: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .google: return .blue
        case .apple: return .black
        case .tiktok: return .pink
        }
    }
}

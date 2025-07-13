import SwiftUI

extension Color {
    // Brand Colors
    static let primaryPurple = Color(red: 0.42, green: 0.15, blue: 0.85) // #6B26D9
    static let primaryBlue = Color(red: 0.14, green: 0.39, blue: 0.92)   // #2463EB
    
    // Background Colors
    static let darkBackground = Color(red: 0.04, green: 0.04, blue: 0.04) // #0A0A0B
    static let cardBackground = Color(red: 0.06, green: 0.06, blue: 0.08)  // #101014
    static let borderColor = Color(red: 0.19, green: 0.19, blue: 0.21)     // #303036
    
    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.63, green: 0.63, blue: 0.67)   // #A1A1AA
    static let mutedText = Color(red: 0.45, green: 0.45, blue: 0.5)        // #737380
}

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.primaryPurple, Color.primaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.cardBackground, Color.cardBackground.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(LinearGradient.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.cardGradient)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

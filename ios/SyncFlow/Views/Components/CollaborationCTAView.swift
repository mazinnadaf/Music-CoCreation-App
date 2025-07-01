import SwiftUI

struct CollaborationCTAView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.largeTitle)
                .foregroundColor(Color.primaryBlue)
                .frame(width: 48, height: 48)
                .background(Color.primaryBlue.opacity(0.2))
                .clipShape(Circle())
            
            Text("This is sounding great!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Ready to take it to the next level? Share your loop or invite a friend to collaborate.")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Share Loop") {
                    // Handle share action
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBackground)
                .foregroundColor(.secondaryText)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryBlue.opacity(0.3), lineWidth: 1)
                )
                
                Button("Invite Collaborator") {
                    // Handle invite action
                }
                .buttonStyle(GradientButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Color.primaryBlue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    CollaborationCTAView()
        .padding()
        .background(Color.darkBackground)
}

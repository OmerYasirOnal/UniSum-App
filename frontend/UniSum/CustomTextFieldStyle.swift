import SwiftUI

struct CustomTextField: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isFocused: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color(.systemGray4), lineWidth: isFocused ? 2 : 1)
            )
            .foregroundColor(Color(.label))
            .accentColor(.blue)
            .font(.system(.body, design: .default))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.2), value: isFocused))
    }
}
extension View {
    func customTextField(isFocused: Bool = false) -> some View {
        self.modifier(CustomTextField(isFocused: isFocused))
    }
}

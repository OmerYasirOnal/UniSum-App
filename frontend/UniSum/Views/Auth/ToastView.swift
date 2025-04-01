import SwiftUI

struct Toast: Equatable {
    let message: LocalizedStringKey
    let type: ToastType
    
    init(stringMessage: String, type: ToastType) {
        self.message = LocalizedStringKey(stringMessage)
        self.type = type
    }
    
    init(message: LocalizedStringKey, type: ToastType) {
        self.message = message
        self.type = type
    }
    
    enum ToastType {
        case error
        case success
        case info
        
        var backgroundColor: Color {
            switch self {
            case .error:
                return Color.red
            case .success:
                return Color.green
            case .info:
                return Color.blue
            }
        }
    }
}

import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    var duration: TimeInterval = 3.0  // default 3 seconds
    
    var body: some View {
        if isShowing {
            // The toast content
            Text(NSLocalizedString(message, comment: ""))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.top, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .shadow(radius: 5)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                    withAnimation {
                                        isShowing = false
                                    }
                                }
                            }
                    }
                }
}
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    var duration: TimeInterval = 3.0

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            ToastView(message: message, isShowing: $isShowing, duration: duration)
                .animation(.easeInOut, value: isShowing)  // animate changes
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, duration: TimeInterval = 3.0) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, duration: duration))
    }
}

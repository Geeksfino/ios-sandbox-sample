import SwiftUI
import Combine
import UIKit

// Simple keyboard avoidance for iOS 14+
struct KeyboardAdaptive: ViewModifier {
    @State private var bottomInset: CGFloat = 0
    private let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomInset)
            .onReceive(willShow.compactMap { $0.userInfo }) { info in
                if let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                   let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                    let frame = frameValue.cgRectValue
                    // Subtract bottom safe area so padding is accurate above the keyboard
                    let keyWindow = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first { $0.isKeyWindow }
                    let safeBottom = keyWindow?.safeAreaInsets.bottom ?? 0
                    withAnimation(.easeOut(duration: duration)) {
                        bottomInset = max(0, frame.height - safeBottom)
                    }
                }
            }
            .onReceive(willHide.compactMap { $0.userInfo }) { info in
                if let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                    withAnimation(.easeOut(duration: duration)) {
                        bottomInset = 0
                    }
                } else {
                    bottomInset = 0
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View { self.modifier(KeyboardAdaptive()) }
}

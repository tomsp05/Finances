import SwiftUI
import Combine

// This class observes keyboard notifications and publishes the keyboard's height.
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellable: AnyCancellable?

    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                guard let userInfo = notification.userInfo,
                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return 0
                }
                // Return the full height of the keyboard's frame
                return keyboardFrame.height
            }

        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        // Merge the two publishers and update the currentHeight property on the main thread
        cancellable = Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .assign(to: \.currentHeight, on: self)
    }
}

// This ViewModifier applies the necessary padding to avoid the keyboard.
struct KeyboardAvoider: ViewModifier {
    @StateObject private var keyboard = KeyboardResponder()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.currentHeight)
            .edgesIgnoringSafeArea(.bottom)
            .animation(.easeOut(duration: 0.16), value: keyboard.currentHeight)
    }
}

extension View {
    func keyboardAvoider() -> some View {
        self.modifier(KeyboardAvoider())
    }
}

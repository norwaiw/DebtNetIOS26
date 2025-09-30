import SwiftUI

struct ScrollViewKeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}
#if os(macOS)
import AppKit
import SwiftUI

/// A multi-line text view with continuous spell checking, which SwiftUI's
/// text fields don't offer on the Mac.
struct SpellCheckingTextView: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.setAccessibilityPlaceholderValue(placeholder)
        textView.string = text
        context.coordinator.textView = textView
        context.coordinator.updatePlaceholder(placeholder)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = context.environment.isEnabled
        context.coordinator.updatePlaceholder(placeholder)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        private var placeholderLabel: NSTextField?

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            placeholderLabel?.isHidden = !text.isEmpty
        }

        func updatePlaceholder(_ placeholder: String) {
            guard let textView else { return }
            if placeholderLabel == nil {
                let label = NSTextField(labelWithString: placeholder)
                label.textColor = .placeholderTextColor
                label.font = textView.font
                label.translatesAutoresizingMaskIntoConstraints = false
                textView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
                    label.topAnchor.constraint(equalTo: textView.topAnchor),
                ])
                placeholderLabel = label
            }
            placeholderLabel?.stringValue = placeholder
            placeholderLabel?.isHidden = !textView.string.isEmpty
        }
    }
}
#endif

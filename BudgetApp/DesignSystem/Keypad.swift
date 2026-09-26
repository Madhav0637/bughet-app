import SwiftUI

/// Typing rupee amounts on the custom keypad, kept free of UI code so it can be tested.
enum KeypadInput {
    enum Key: Hashable {
        case digit(Int)
        case doubleZero
        case delete
    }

    /// Up to ₹99,99,99,999.
    static let maxDigits = 9

    /// The digits after pressing `key`. No leading zeros, and nothing beyond `maxDigits`.
    static func apply(_ key: Key, to text: String) -> String {
        switch key {
        case .digit(let digit):
            guard !(text.isEmpty && digit == 0), text.count < maxDigits else { return text }
            return text + String(digit)
        case .doubleZero:
            guard !text.isEmpty else { return text }
            return text + String(repeating: "0", count: min(2, maxDigits - text.count))
        case .delete:
            return String(text.dropLast())
        }
    }
}

/// The number pad for rupee amounts: 1–9, 00, 0 and delete. Hold delete to clear.
struct Keypad: View {
    @Binding var text: String

    private let rows: [[KeypadInput.Key]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.doubleZero, .digit(0), .delete],
    ]

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: text)
    }

    @ViewBuilder
    private func keyButton(_ key: KeypadInput.Key) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { text = KeypadInput.apply(key, to: text) }
        } label: {
            Group {
                switch key {
                case .digit(let digit): Text("\(digit)")
                case .doubleZero: Text("00")
                case .delete: Image(systemName: "delete.left").font(.system(size: 24, weight: .medium))
                }
            }
            .font(.system(size: 30, weight: .medium, design: .rounded))
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(.rect)
        }
        .buttonStyle(KeypadKeyStyle())
        .accessibilityLabel(accessibilityLabel(for: key))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                guard key == .delete else { return }
                withAnimation(.snappy) { text = "" }
            }
        )
    }

    private func accessibilityLabel(for key: KeypadInput.Key) -> String {
        switch key {
        case .digit(let digit): "\(digit)"
        case .doubleZero: "Double zero"
        case .delete: "Delete"
        }
    }
}

/// A soft round glow behind a key while it's pressed.
private struct KeypadKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.surface2)
                    .opacity(configuration.isPressed ? 1 : 0)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

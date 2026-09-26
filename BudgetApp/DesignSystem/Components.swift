import SwiftUI

/// A rupee amount with a smaller, quieter ₹ in front: the style of every hero number. Digits roll when it changes.
struct AmountText: View {
    let amount: Int
    var size: CGFloat = 56
    var color: Color = .ink

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.05) {
            Text("₹")
                .font(.system(size: size * 0.58, weight: .semibold, design: .rounded))
                .foregroundStyle(.ink2)
            Text(amount.indianGrouped)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .tracking(-size * 0.02)
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(amount)))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(amount.inr)
    }
}

/// White (or near-black) rounded card. Light mode adds a hairline and a whisper of shadow; dark mode stays flat.
struct CardBackground: ViewModifier {
    var padding: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface, in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                if colorScheme == .light {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.hairline)
                }
            }
            .shadow(color: .black.opacity(colorScheme == .light ? 0.035 : 0), radius: 10, y: 3)
    }
}

extension View {
    func card(padding: CGFloat = 20) -> some View { modifier(CardBackground(padding: padding)) }
}

/// A category's emoji on a soft rounded tile.
struct EmojiTile: View {
    let emoji: String
    var size: CGFloat = 42

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Color.surface2, in: .rect(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// An SF Symbol on a soft rounded tile, for settings rows.
struct IconTile: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.ink)
            .frame(width: 32, height: 32)
            .background(Color.surface2, in: .rect(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Shrinks a little while pressed, with a spring.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

/// A segmented control whose thumb slides between options.
struct PillPicker<Value: Hashable & Identifiable, Label: View>: View {
    @Binding var selection: Value
    let options: [Value]
    @ViewBuilder var label: (Value) -> Label

    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy(duration: 0.3)) { selection = option }
                } label: {
                    label(option)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.ink : Color.ink2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.thumb)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.surface2, in: .capsule)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// A rounded bar that fills from the left, growing in when it first appears.
struct ProgressBar: View {
    /// 0 to 1; anything above 1 shows full.
    let value: Double
    var tint: Color
    var track: Color = .surface2
    var height: CGFloat = 8

    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let fraction = min(max(value, 0), 1)
        Capsule()
            .fill(track)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    if fraction > 0 {
                        Capsule()
                            .fill(tint)
                            .frame(width: max(height, geometry.size.width * (shown ? fraction : 0)))
                    }
                }
            }
            .frame(height: height)
            .animation(.spring(duration: 0.6), value: fraction)
            .onAppear {
                if reduceMotion { shown = true } else {
                    withAnimation(.spring(duration: 0.9, bounce: 0.15).delay(0.1)) { shown = true }
                }
            }
            .accessibilityHidden(true)
    }
}

/// A pill for filters and choices. Selected is solid ink, or the highlight colour with a check.
struct Chip: View {
    enum SelectedStyle { case ink, highlight }

    let title: String
    var emoji: String?
    let isSelected: Bool
    var selectedStyle: SelectedStyle = .ink
    var restingBackground: Color = .surface

    @Environment(\.highlight) private var highlight

    var body: some View {
        HStack(spacing: 6) {
            if let emoji { Text(emoji) }
            Text(title).lineLimit(1)
            if isSelected, selectedStyle == .highlight {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.heavy))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .font(.subheadline.weight(isSelected ? .semibold : .medium))
        .foregroundStyle(foreground)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(background, in: .capsule)
        .overlay {
            if !isSelected { Capsule().strokeBorder(Color.hairline) }
        }
        .contentShape(.capsule)
        .animation(.snappy(duration: 0.25), value: isSelected)
    }

    private var foreground: Color {
        guard isSelected else { return .ink }
        return selectedStyle == .ink ? .canvas : .onHighlight
    }

    private var background: Color {
        guard isSelected else { return restingBackground }
        return selectedStyle == .ink ? .ink : highlight.fill
    }
}

/// A section title with an optional "See all ›" style link.
struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.ink)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.ink2)
                }
                .buttonStyle(.pressable)
            }
        }
    }
}

/// "↓ 12% vs same time last month". Spending less gets the highlight colour; spending more stays neutral.
struct ChangePill: View {
    /// -0.12 is 12% less.
    let change: Double
    /// "same time last month", "August".
    let comparedWith: String

    @Environment(\.highlight) private var highlight

    var body: some View {
        let percent = (abs(change) * 100).rounded()
        HStack(spacing: 5) {
            if percent == 0 {
                Text("Same as \(comparedWith)")
            } else {
                Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(change < 0 ? highlight.text : Color.ink2)
                Text("\(Int(percent))% vs \(comparedWith)")
            }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.surface2, in: .capsule)
        .contentTransition(.numericText())
    }
}

/// The app's mark: a mint circle, an amber pill and a periwinkle pill on a graphite tile.
struct KokuLogo: View {
    var size: CGFloat = 32

    var body: some View {
        let unit = size / 512
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 118 * unit, style: .continuous)
                .fill(Color(hex: 0x111827))
            Circle()
                .fill(Color(hex: 0x34D399))
                .frame(width: 144 * unit, height: 144 * unit)
                .offset(x: 122 * unit, y: 122 * unit)
            Capsule()
                .fill(Color(hex: 0xFBBF24))
                .frame(width: 144 * unit, height: 82 * unit)
                .offset(x: 122 * unit, y: 266 * unit)
            Capsule()
                .fill(Color(hex: 0x818CF8))
                .frame(width: 114 * unit, height: 185 * unit)
                .offset(x: 266 * unit, y: 163 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The big round add button, in the highlight colour.
struct AddButton: View {
    let action: () -> Void

    @Environment(\.highlight) private var highlight
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.onHighlight)
                .frame(width: 62, height: 62)
                .background(highlight.fill, in: .circle)
                .shadow(color: highlight.fill.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(.impact(weight: .medium), trigger: taps)
        .accessibilityLabel("Add expense")
        .accessibilityIdentifier("addExpense")
    }
}

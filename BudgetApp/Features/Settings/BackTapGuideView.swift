import SwiftUI

/// Step-by-step instructions for connecting Back Tap to the Log Expense action.
struct BackTapGuideView: View {
    @Environment(\.highlight) private var highlight

    private let steps: [(title: String, detail: String)] = [
        ("Create the shortcut",
         "Open the Shortcuts app, tap +, then Add Action. Search for \"Log Expense\" and add it."),
        ("Leave the fields empty",
         "Don't fill in On what?, Amount or Category. Empty fields mean the shortcut asks for them every time."),
        ("Name it",
         "Rename the shortcut to \"Log Expense\" and tap Done."),
        ("Connect Back Tap",
         "Open Settings → Accessibility → Touch → Back Tap → Double Tap, and choose Log Expense."),
        ("Try it",
         "With your iPhone unlocked, double-tap the back. Answer the three questions and the expense is saved."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Log an expense in about five seconds, without opening Koku.")
                    .font(.subheadline)
                    .foregroundStyle(.ink2)
                    .padding(.bottom, 4)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.onHighlight)
                            .frame(width: 32, height: 32)
                            .background(highlight.fill, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.headline)
                                .foregroundStyle(.ink)
                            Text(step.detail)
                                .font(.subheadline)
                                .foregroundStyle(.ink2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .card(padding: 16)
                }

                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.onHighlight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(highlight.fill, in: .capsule)
                }
                .buttonStyle(.pressable)
                .padding(.top, 8)

                Text("Back Tap needs iPhone 8 or later. You can also choose Triple Tap instead of Double Tap.")
                    .font(.footnote)
                    .foregroundStyle(.ink2)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Color.canvas)
        .navigationTitle("Set Up Back Tap")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { BackTapGuideView() }
}

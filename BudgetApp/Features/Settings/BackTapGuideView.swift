import SwiftUI

/// Step-by-step instructions for connecting Back Tap to the Log Expense action.
struct BackTapGuideView: View {
    private let steps: [(icon: String, title: String, detail: String)] = [
        ("square.stack.3d.up", "Create the shortcut",
         "Open the Shortcuts app, tap +, then Add Action. Search for \"Log Expense\" and add it."),
        ("hand.raised", "Leave the fields empty",
         "Don't fill in On what?, Amount or Category. Empty fields mean the shortcut asks for them every time."),
        ("pencil", "Name it",
         "Rename the shortcut to \"Log Expense\" and tap Done."),
        ("gearshape", "Connect Back Tap",
         "Open Settings → Accessibility → Touch → Back Tap → Double Tap, and choose Log Expense."),
        ("iphone.gen3.radiowaves.left.and.right", "Try it",
         "With your iPhone unlocked, double-tap the back. Answer the three questions and the expense is saved."),
    ]

    var body: some View {
        List {
            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                }
            }

            Section {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.icon)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1). \(step.title)")
                                .font(.headline)
                            Text(step.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                Text("Back Tap needs iPhone 8 or later. You can also choose Triple Tap instead of Double Tap.")
            }
        }
        .navigationTitle("Set Up Back Tap")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { BackTapGuideView() }
}

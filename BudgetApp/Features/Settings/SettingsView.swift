import SwiftData
import SwiftUI

/// The Settings tab: theme and highlight colour, the monthly budget and its alerts, categories, Back Tap and export.
struct SettingsView: View {
    @AppStorage(SettingsKey.appearance) private var appearance = Appearance.system
    @AppStorage(SettingsKey.highlight) private var highlight = Highlight.mint
    @AppStorage(SettingsKey.monthlyBudget) private var monthlyBudget = 0
    @AppStorage(SettingsKey.budgetAlerts) private var budgetAlerts = true
    @Query private var categories: [Category]

    @State private var isEditingBudget = false
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.ink)
                        PillPicker(selection: $appearance, options: Appearance.allCases) { option in
                            Label(option.title, systemImage: option.systemImage)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Highlight")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.ink)
                            Spacer()
                            Text(highlight.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(highlight.text)
                                .contentTransition(.interpolate)
                        }
                        HighlightSwatches(selection: $highlight)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.surface)

                Section {
                    Button { isEditingBudget = true } label: {
                        row(icon: "target", title: "Monthly budget", subtitle: "Starts again on the 1st") {
                            Text(monthlyBudget > 0 ? monthlyBudget.inr : "Not set")
                                .monospacedDigit()
                                .foregroundStyle(.ink2)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.ink3)
                        }
                    }
                    Toggle(isOn: $budgetAlerts) {
                        row(icon: "bell.badge", title: "Budget alerts", subtitle: "At 80% and 100% of your budget") {}
                    }
                    .tint(highlight.fill)
                    .disabled(monthlyBudget == 0)
                } header: {
                    Text("Budget")
                } footer: {
                    if monthlyBudget > 0, budgetAlerts, notificationsDenied {
                        Text("Notifications are off for Koku, so alerts only appear inside the app. You can turn them on in iOS Settings → Apps → Koku.")
                    }
                }
                .listRowBackground(Color.surface)

                Section("Data") {
                    NavigationLink { CategoriesView() } label: {
                        row(icon: "square.grid.2x2", title: "Categories") {
                            Text("\(categories.count)").foregroundStyle(.ink2)
                        }
                    }
                    NavigationLink { BackTapGuideView() } label: {
                        row(icon: "hand.tap", title: "Set up Back Tap", subtitle: "Log in 5 seconds without opening the app") {}
                    }
                    NavigationLink { ExportView() } label: {
                        row(icon: "square.and.arrow.up", title: "Export", subtitle: "CSV spreadsheet or PDF report") {}
                    }
                }
                .listRowBackground(Color.surface)

                Section {
                    footer
                }
                .listRowBackground(Color.clear)
            }
            .kokuList()
            .navigationTitle("Settings")
            .sheet(isPresented: $isEditingBudget) { BudgetView() }
            .task { notificationsDenied = await BudgetNotifier.isDenied() }
            .onChange(of: budgetAlerts) {
                guard budgetAlerts else { return }
                Task {
                    await BudgetNotifier.requestPermission()
                    notificationsDenied = await BudgetNotifier.isDenied()
                }
            }
        }
    }

    private func row<Trailing: View>(icon: String, title: String, subtitle: String? = nil,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            IconTile(systemImage: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.ink2)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.vertical, 2)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            KokuLogo(size: 44)
            Text("koku \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.headline)
                .foregroundStyle(.ink)
            HStack(spacing: 6) {
                Circle().fill(highlight.fill).frame(width: 6, height: 6)
                Text("Everything stays on this iPhone.")
            }
            .font(.footnote)
            .foregroundStyle(.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// Six colour dots; the chosen one has a ring and a check.
private struct HighlightSwatches: View {
    @Binding var selection: Highlight

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Highlight.allCases) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Circle()
                        .fill(option.fill)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(.onHighlight)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(4)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.ink, lineWidth: 2)
                                .opacity(isSelected ? 1 : 0)
                        }
                        .scaleEffect(isSelected ? 1.08 : 1)
                        .frame(maxWidth: .infinity)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

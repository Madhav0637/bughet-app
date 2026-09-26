import Charts
import SwiftData
import SwiftUI

/// A week, month or year at a glance, now or in the past: the total and how it compares, spending day by day,
/// categories, a few highlights and the top merchants.
struct InsightsView: View {
    @Query private var expenses: [Expense]
    @AppStorage(SettingsKey.insightsPeriod) private var period = Period.month
    /// 0 is the current period, -1 the one before, and so on.
    @State private var offset = 0
    /// Which way the period title slides when moving between periods.
    @State private var movingBack = true

    var body: some View {
        let calculator = PeriodCalculator()
        let range = calculator.range(of: period, offset: offset)
        let insights = PeriodInsights(expenses: expenses, period: period, range: range, calculator: calculator)
        let comparison = PeriodComparison(expenses: expenses, period: period, offset: offset, calculator: calculator)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PillPicker(selection: $period, options: Period.allCases) { Text($0.title) }
                    navigator(range: range, calculator: calculator)
                    hero(insights: insights, comparison: comparison, calculator: calculator)
                        .gesture(swipeBetweenPeriods)
                    if insights.total > 0 {
                        SpendingChart(insights: insights, period: period)
                        CategoryBreakdown(insights: insights)
                        highlights(insights)
                        topMerchants(insights)
                    } else {
                        emptyState(range: range)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .animation(.snappy, value: range.lowerBound)
            }
            .scrollIndicators(.hidden)
            .background(Color.canvas)
            .navigationTitle("Insights")
            .onChange(of: period) { offset = 0 }
        }
    }

    // MARK: Period navigation

    private func navigator(range: Range<Date>, calculator: PeriodCalculator) -> some View {
        HStack {
            stepButton(systemImage: "chevron.left", label: "Previous \(period.title.lowercased())", back: true)
            Spacer()
            Text(title(for: range, calculator: calculator))
                .font(.headline)
                .foregroundStyle(.ink)
                .id(range.lowerBound)
                .transition(.push(from: movingBack ? .leading : .trailing))
            Spacer()
            stepButton(systemImage: "chevron.right", label: "Next \(period.title.lowercased())", back: false)
                .disabled(offset >= 0)
                .opacity(offset >= 0 ? 0.35 : 1)
        }
        .clipped()
    }

    private func stepButton(systemImage: String, label: String, back: Bool) -> some View {
        Button { step(back: back) } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.ink)
                .frame(width: 36, height: 36)
                .background(Color.surface2, in: .circle)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
        .sensoryFeedback(.selection, trigger: offset)
    }

    private func step(back: Bool) {
        guard back || offset < 0 else { return }
        movingBack = back
        withAnimation(.snappy(duration: 0.35)) { offset += back ? -1 : 1 }
    }

    private var swipeBetweenPeriods: some Gesture {
        DragGesture(minimumDistance: 30).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            if value.translation.width > 60 { step(back: true) }
            if value.translation.width < -60 { step(back: false) }
        }
    }

    private func title(for range: Range<Date>, calculator: PeriodCalculator) -> String {
        let calendar = calculator.calendar
        switch period {
        case .week:
            let last = calendar.date(byAdding: .day, value: -1, to: range.upperBound) ?? range.upperBound
            let sameMonth = calendar.isDate(range.lowerBound, equalTo: last, toGranularity: .month)
            let start = range.lowerBound.formatted(sameMonth ? .dateTime.day() : .dateTime.day().month(.abbreviated))
            return "\(start) – \(last.formatted(.dateTime.day().month(.abbreviated)))"
        case .month:
            return range.lowerBound.formatted(.dateTime.month(.wide).year())
        case .year:
            return range.lowerBound.formatted(.dateTime.year())
        }
    }

    // MARK: Sections

    private func hero(insights: PeriodInsights, comparison: PeriodComparison, calculator: PeriodCalculator) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AmountText(amount: insights.total, size: 52)
                .animation(.snappy, value: insights.total)
            if let change = comparison.change {
                ChangePill(change: change, comparedWith: comparedWith(comparison, calculator: calculator))
            }
            if insights.count > 0 {
                Text("\(insights.count.counted("expense")) · \(insights.averagePerDay.inr) a day on average")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private func comparedWith(_ comparison: PeriodComparison, calculator: PeriodCalculator) -> String {
        if comparison.isPartial { return "same time \(period.previousPhrase)" }
        let previous = calculator.range(of: period, offset: offset - 1).lowerBound
        return switch period {
        case .week: "the week before"
        case .month: previous.formatted(.dateTime.month(.wide))
        case .year: previous.formatted(.dateTime.year())
        }
    }

    private func highlights(_ insights: PeriodInsights) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            if let biggest = insights.biggest {
                StatTile(title: "Biggest spend", value: biggest.amount.inr,
                         detail: "\(biggest.merchant) · \(biggest.date.formatted(.dateTime.day().month(.abbreviated)))")
            }
            if let frequent = insights.mostFrequent {
                StatTile(title: "Most visited", value: frequent.name, detail: frequent.count.counted("time"))
            }
            StatTile(title: "Average", value: insights.averagePerDay.inr, detail: "per day")
            StatTile(title: "No-spend days", value: insights.noSpendDays > 0 ? "\(insights.noSpendDays) 🎉" : "0",
                     detail: "of \(insights.elapsedDays.counted("day"))")
        }
    }

    private func topMerchants(_ insights: PeriodInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top merchants")
            VStack(spacing: 0) {
                ForEach(Array(insights.topMerchants.prefix(5).enumerated()), id: \.element.id) { index, merchant in
                    if index > 0 { Divider().overlay(Color.hairline).padding(.leading, 54) }
                    HStack(spacing: 12) {
                        EmojiTile(emoji: merchant.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(merchant.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.ink)
                                .lineLimit(1)
                            Text(merchant.count.counted("time"))
                                .font(.footnote)
                                .foregroundStyle(.ink2)
                        }
                        Spacer()
                        Text(merchant.amount.inr)
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.ink)
                    }
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                }
            }
            .card(padding: 16)
        }
    }

    private func emptyState(range: Range<Date>) -> some View {
        VStack(spacing: 10) {
            Text("🌱").font(.system(size: 44))
            Text(offset == 0 ? "Nothing spent \(period.phrase)" : "Nothing spent in this \(period.title.lowercased())")
                .font(.headline)
                .foregroundStyle(.ink)
            Text("Charts and highlights appear once there's spending to show.")
                .font(.subheadline)
                .foregroundStyle(.ink2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .card()
    }
}

/// Bars for each day (or each month of a year). The tapped bar, or else the peak, is in the highlight colour
/// with its amount; a dashed line marks the average so far.
private struct SpendingChart: View {
    let insights: PeriodInsights
    let period: Period

    @Environment(\.highlight) private var highlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDate: Date?
    @State private var grown = false

    var body: some View {
        let unit: Calendar.Component = insights.bucketsAreMonths ? .month : .day
        let focused = selectedBucket ?? insights.peak
        VStack(alignment: .leading, spacing: 4) {
            Text(insights.bucketsAreMonths ? "Month by month" : "Day by day")
                .font(.headline)
                .foregroundStyle(.ink)
            Text(caption(for: focused))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.ink2)
                .contentTransition(.numericText())
                .padding(.bottom, 12)

            Chart {
                ForEach(insights.buckets) { bucket in
                    BarMark(x: .value("Date", bucket.start, unit: unit),
                            y: .value("Spent", grown ? bucket.amount : 0),
                            width: .ratio(0.62))
                        .clipShape(Capsule())
                        .foregroundStyle(bucket.id == focused?.id ? highlight.fill : Color.chartBar)
                }
                if insights.averagePerBucket > 0 {
                    RuleMark(y: .value("Average", insights.averagePerBucket))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        .foregroundStyle(Color.ink3)
                        .annotation(position: .top, alignment: .trailing, spacing: 2) {
                            Text("avg \(insights.averagePerBucket.inr)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.ink2)
                        }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: axisDates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(axisLabel(for: date))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.ink2)
                        }
                    }
                }
            }
            .frame(height: 170)
            .animation(.snappy, value: focused?.id)
        }
        .card()
        .sensoryFeedback(.selection, trigger: selectedBucket?.id)
        .onAppear {
            if reduceMotion { grown = true } else { withAnimation(.spring(duration: 0.8, bounce: 0.15)) { grown = true } }
        }
        .onChange(of: insights.range) { selectedDate = nil }
    }

    private var selectedBucket: PeriodInsights.Bucket? {
        guard let selectedDate else { return nil }
        return insights.buckets.last { $0.start <= selectedDate }
    }

    private func caption(for bucket: PeriodInsights.Bucket?) -> String {
        guard let bucket else { return "Tap a bar to see its total" }
        let when = insights.bucketsAreMonths
            ? bucket.start.formatted(.dateTime.month(.wide))
            : bucket.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let prefix = selectedBucket == nil ? "Peak · " : ""
        return "\(prefix)\(when) · \(bucket.amount.inr)"
    }

    private var axisDates: [Date] {
        let starts = insights.buckets.map(\.start)
        switch period {
        case .week, .year: return starts
        case .month: return starts.enumerated().filter { $0.offset % 7 == 0 }.map(\.element)
        }
    }

    private func axisLabel(for date: Date) -> String {
        switch period {
        case .week: date.formatted(.dateTime.weekday(.narrow))
        case .month: date.formatted(.dateTime.day())
        case .year: date.formatted(.dateTime.month(.narrow))
        }
    }
}

/// One bar split by category (the biggest in the highlight colour, the rest in greys), then every category.
private struct CategoryBreakdown: View {
    let insights: PeriodInsights

    @Environment(\.highlight) private var highlight

    var body: some View {
        let totals = insights.categoryTotals
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Categories")
                    .font(.headline)
                    .foregroundStyle(.ink)
                Spacer()
                Text(totals.count.counted("category", "categories"))
                    .font(.footnote)
                    .foregroundStyle(.ink2)
            }

            GeometryReader { geometry in
                let spacing: CGFloat = 3
                let available = geometry.size.width - spacing * CGFloat(max(totals.count - 1, 0))
                HStack(spacing: spacing) {
                    ForEach(Array(totals.enumerated()), id: \.element.category.id) { index, item in
                        Capsule()
                            .fill(index == 0 ? highlight.fill : Color.ink.opacity(max(0.12, 0.7 - Double(index) * 0.15)))
                            .frame(width: max(4, available * share(item)))
                    }
                }
            }
            .frame(height: 10)
            .animation(.snappy, value: insights.total)

            VStack(spacing: 14) {
                ForEach(Array(totals.enumerated()), id: \.element.category.id) { index, item in
                    HStack(spacing: 12) {
                        EmojiTile(emoji: item.category.emoji, size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.category.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.ink)
                            Text(item.count.counted("expense"))
                                .font(.footnote)
                                .foregroundStyle(.ink2)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(item.amount.inr)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.ink)
                            Text(share(item).formatted(.percent.precision(.fractionLength(0))))
                                .font(.footnote.weight(index == 0 ? .bold : .regular))
                                .foregroundStyle(index == 0 ? highlight.text : Color.ink2)
                        }
                        .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .card()
    }

    private func share(_ item: SpendingSummary.CategoryTotal) -> Double {
        insights.total > 0 ? Double(item.amount) / Double(insights.total) : 0
    }
}

/// A small card with a label, a big value and a detail line.
private struct StatTile: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.ink2)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.ink2)
                .lineLimit(1)
        }
        .card(padding: 16)
        .accessibilityElement(children: .combine)
    }
}

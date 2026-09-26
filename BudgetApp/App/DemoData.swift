#if DEBUG
import Foundation
import SwiftData

/// About 11 weeks of believable spending for screenshots and UI tests. The same every run, relative to today.
enum DemoData {
    private struct Habit {
        let merchant: String
        let category: String
        let amounts: ClosedRange<Int>
        /// Chance of happening on any given day.
        let chance: Double
        let hours: ClosedRange<Int>
    }

    private static let habits: [Habit] = [
        Habit(merchant: "Chai Point", category: "Food", amounts: 40...90, chance: 0.45, hours: 9...11),
        Habit(merchant: "Zomato", category: "Food", amounts: 280...650, chance: 0.32, hours: 19...22),
        Habit(merchant: "Swiggy", category: "Food", amounts: 220...540, chance: 0.22, hours: 13...14),
        Habit(merchant: "Blinkit", category: "Shopping", amounts: 180...900, chance: 0.22, hours: 10...21),
        Habit(merchant: "Uber", category: "Transport", amounts: 120...380, chance: 0.32, hours: 8...20),
        Habit(merchant: "Rapido", category: "Transport", amounts: 60...160, chance: 0.28, hours: 8...19),
        Habit(merchant: "Myntra", category: "Shopping", amounts: 900...3_499, chance: 0.04, hours: 12...23),
        Habit(merchant: "Amazon", category: "Shopping", amounts: 300...2_200, chance: 0.05, hours: 12...23),
        Habit(merchant: "PVR", category: "Entertainment", amounts: 350...900, chance: 0.05, hours: 18...21),
        Habit(merchant: "Apollo Pharmacy", category: "Health", amounts: 150...700, chance: 0.04, hours: 10...20),
    ]

    /// Paid on the same day every month.
    private static let bills: [(day: Int, merchant: String, category: String, amount: Int)] = [
        (5, "Netflix", "Entertainment", 649),
        (8, "Electricity", "Bills", 2_140),
        (12, "Jio recharge", "Bills", 299),
        (18, "Spotify", "Entertainment", 119),
    ]

    private static let notes = ["team dinner", "split with friends", "birthday gift", "late night 🌙", "weekly groceries"]

    static func seed(into context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws {
        try CategoryService(context: context).seedDefaultsIfNeeded()
        let categories = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Category>()).map { ($0.name, $0) })
        var random = SeededGenerator(seed: 2026)
        let today = calendar.startOfDay(for: now)

        for daysAgo in 0..<80 {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            // A few quiet days, so "no-spend days" has something to celebrate.
            if [3, 11, 17, 26, 40].contains(daysAgo) { continue }

            for habit in habits where Double.random(in: 0..<1, using: &random) < habit.chance {
                let hour = Int.random(in: habit.hours, using: &random)
                let minute = Int.random(in: 0..<60, using: &random)
                guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), date <= now,
                      let category = categories[habit.category] else { continue }
                let note = Double.random(in: 0..<1, using: &random) < 0.06 ? notes.randomElement(using: &random) : nil
                context.insert(Expense(merchant: habit.merchant, amount: Int.random(in: habit.amounts, using: &random),
                                       date: date, category: category, note: note))
            }

            let dayOfMonth = calendar.component(.day, from: day)
            for bill in bills where bill.day == dayOfMonth {
                guard let date = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: day), date <= now,
                      let category = categories[bill.category] else { continue }
                context.insert(Expense(merchant: bill.merchant, amount: bill.amount, date: date, category: category))
            }
        }
        try context.save()
    }
}

/// SplitMix64: a tiny random generator that gives the same numbers for the same seed.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
#endif

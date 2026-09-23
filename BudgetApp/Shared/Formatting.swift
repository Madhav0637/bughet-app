import Foundation

extension Int {
    /// Whole rupees with Indian digit grouping, e.g. ₹1,23,456.
    var inr: String {
        formatted(.currency(code: "INR").precision(.fractionLength(0)).locale(Locale(identifier: "en_IN")))
    }
}

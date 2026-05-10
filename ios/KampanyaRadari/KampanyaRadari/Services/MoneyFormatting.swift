import Foundation

extension Double {
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "tr_TR")
        let number = NSNumber(value: self)
        return "\(formatter.string(from: number) ?? "0") TL"
    }

    var moneyInputText: String {
        guard self > 0 else { return "" }
        if rounded() == self {
            return String(Int(self))
        }
        return String(self)
    }
}

extension Date {
    var shortDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

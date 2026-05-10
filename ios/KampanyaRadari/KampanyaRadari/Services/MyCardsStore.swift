import Foundation
import Observation

@Observable
final class MyCardsStore {
    private let key = "myCardBanks"
    private(set) var banks: Set<String> = []

    init() {
        banks = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func contains(_ bank: String) -> Bool {
        banks.contains(bank)
    }

    func toggle(_ bank: String) {
        if banks.contains(bank) {
            banks.remove(bank)
        } else {
            banks.insert(bank)
        }
        save()
    }

    func clear() {
        banks = []
        save()
    }

    func replace(with newBanks: Set<String>) {
        banks = newBanks
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(banks), forKey: key)
    }
}

import Foundation
import Observation

@Observable
final class MyCardsStore {
    private let key = "myCardBanks"
    @ObservationIgnored private var saveTask: Task<Void, Never>?
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
        guard !banks.isEmpty else { return }
        banks = []
        save()
    }

    func replace(with newBanks: Set<String>) {
        guard banks != newBanks else { return }
        banks = newBanks
        save()
    }

    private func save() {
        let key = key
        let snapshot = Array(banks)
        saveTask?.cancel()
        saveTask = Task.detached(priority: .utility) {
            guard !Task.isCancelled else { return }
            UserDefaults.standard.set(snapshot, forKey: key)
        }
    }
}

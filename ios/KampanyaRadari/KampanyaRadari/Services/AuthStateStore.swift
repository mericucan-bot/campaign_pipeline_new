import Foundation
import Observation

@Observable
final class AuthStateStore {
    private let displayNameKey = "authDisplayName"
    private let isGuestKey = "authIsGuest"

    var displayName: String
    var isGuest: Bool

    init() {
        displayName = UserDefaults.standard.string(forKey: displayNameKey) ?? "Misafir"
        isGuest = UserDefaults.standard.object(forKey: isGuestKey) as? Bool ?? true
    }

    var statusText: String {
        isGuest ? "Misafir mod" : displayName
    }

    func continueAsGuest() {
        displayName = "Misafir"
        isGuest = true
        save()
    }

    func previewSignIn(as name: String) {
        displayName = name
        isGuest = false
        save()
    }

    func signOut() {
        continueAsGuest()
    }

    private func save() {
        UserDefaults.standard.set(displayName, forKey: displayNameKey)
        UserDefaults.standard.set(isGuest, forKey: isGuestKey)
    }
}

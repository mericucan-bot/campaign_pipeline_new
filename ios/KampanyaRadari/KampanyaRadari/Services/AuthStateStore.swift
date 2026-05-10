import Foundation
import Observation

@MainActor
@Observable
final class AuthStateStore {
    private let displayNameKey = "authDisplayName"
    private let isGuestKey = "authIsGuest"
    private let sessionKey = "authSession"
    private let authService = SupabaseAuthService()

    var displayName: String
    var isGuest: Bool
    var email: String?
    var userID: String?
    var authMessage: String?
    var isLoading = false
    var passwordResetAccessToken: String?
    var plan: SubscriptionPlan = .free
    private(set) var session: AuthSession?

    init() {
        let savedSession = Self.loadSession(key: sessionKey)
        session = savedSession
        displayName = UserDefaults.standard.string(forKey: displayNameKey) ?? savedSession?.user.email ?? "Misafir"
        isGuest = UserDefaults.standard.object(forKey: isGuestKey) as? Bool ?? (savedSession == nil)
        email = savedSession?.user.email
        userID = savedSession?.user.id
    }

    var statusText: String {
        isGuest ? "Misafir mod" : displayName
    }

    var isAuthenticated: Bool {
        session != nil && !isGuest
    }

    var isAuthMessagePositive: Bool {
        guard let authMessage else { return false }
        return authMessage.hasPrefix("Kayıt alındı")
            || authMessage.hasPrefix("Hesap oluşturuldu")
            || authMessage.hasPrefix("Giriş başarılı")
            || authMessage.hasPrefix("Şifre sıfırlama")
    }

    func continueAsGuest() {
        displayName = "Misafir"
        isGuest = true
        email = nil
        userID = nil
        session = nil
        authMessage = nil
        save()
    }

    func previewSignIn(as name: String) {
        displayName = name
        isGuest = false
        authMessage = "Bu sadece ön izleme. Gerçek hesap için e-posta ile giriş yap."
        save()
    }

    func signOut() {
        let accessToken = session?.accessToken
        continueAsGuest()
        if let accessToken {
            Task {
                await authService.signOut(accessToken: accessToken)
            }
        }
    }

    func signIn(email: String, password: String) async {
        await authenticate(email: email, password: password, isSignUp: false)
    }

    func signUp(email: String, password: String) async {
        await authenticate(email: email, password: password, isSignUp: true)
    }

    func sendPasswordReset(email: String) async {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedEmail.contains("@") else {
            authMessage = "Şifre sıfırlama için geçerli e-posta girmen gerekiyor."
            return
        }

        isLoading = true
        authMessage = nil

        do {
            try await authService.sendPasswordReset(email: cleanedEmail)
            authMessage = "Şifre sıfırlama maili gönderildi. Mail kutunu kontrol et."
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    func handlePasswordResetURL(_ url: URL) {
        guard let token = Self.recoveryAccessToken(from: url) else { return }
        passwordResetAccessToken = token
        authMessage = nil
    }

    func clearPasswordResetToken() {
        passwordResetAccessToken = nil
    }

    func updatePassword(accessToken: String, password: String) async {
        guard password.count >= 6 else {
            authMessage = "Yeni şifre en az 6 karakter olmalı."
            return
        }

        isLoading = true
        authMessage = nil

        do {
            try await authService.updatePassword(accessToken: accessToken, password: password)
            authMessage = "Şifre güncellendi. Yeni şifrenle giriş yapabilirsin."
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func authenticate(email: String, password: String, isSignUp: Bool) async {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedEmail.contains("@"), password.count >= 6 else {
            authMessage = "E-posta geçerli olmalı, şifre en az 6 karakter olmalı."
            return
        }

        isLoading = true
        authMessage = nil

        do {
            let newSession = isSignUp
                ? try await authService.signUp(email: cleanedEmail, password: password)
                : try await authService.signIn(email: cleanedEmail, password: password)
            apply(session: newSession)
            authMessage = isSignUp ? "Hesap oluşturuldu ve giriş yapıldı." : "Giriş başarılı."
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func apply(session newSession: AuthSession) {
        session = newSession
        email = newSession.user.email
        userID = newSession.user.id
        displayName = newSession.user.email ?? "Kullanıcı"
        isGuest = false
        save()
    }

    private func save() {
        UserDefaults.standard.set(displayName, forKey: displayNameKey)
        UserDefaults.standard.set(isGuest, forKey: isGuestKey)
        if let session, let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }

    private static func loadSession(key: String) -> AuthSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    private static func recoveryAccessToken(from url: URL) -> String? {
        let fragmentItems = URLComponents(string: "?\(url.fragment ?? "")")?.queryItems ?? []
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let allItems = fragmentItems + queryItems
        let type = allItems.first(where: { $0.name == "type" })?.value
        guard type == nil || type == "recovery" else { return nil }
        return allItems.first(where: { $0.name == "access_token" })?.value
    }
}

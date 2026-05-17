import Foundation
import Observation

@MainActor
@Observable
final class AuthStateStore {
    private let displayNameKey = "authDisplayName"
    private let authProviderKey = "authProvider"
    private let isGuestKey = "authIsGuest"
    private let sessionKey = "authSession"
    private let refreshLeeway: TimeInterval = 5 * 60
    private let authService = SupabaseAuthService()
    private let profileService = UserProfileService()

    var displayName: String
    var isGuest: Bool
    var email: String?
    var userID: String?
    var authProvider: AuthProvider
    var authMessage: String?
    var isLoading = false
    var passwordResetAccessToken: String?
    var plan: SubscriptionPlan = .free
    private(set) var session: AuthSession?

    init() {
        let savedSession = Self.loadSession(key: sessionKey)
        session = savedSession
        displayName = "Misafir"
        authProvider = AuthProvider(rawValue: UserDefaults.standard.string(forKey: authProviderKey) ?? "")
            ?? (savedSession == nil ? .guest : (Self.isApplePrivateRelay(savedSession?.user.email) ? .apple : .email))
        isGuest = UserDefaults.standard.object(forKey: isGuestKey) as? Bool ?? (savedSession == nil)
        email = savedSession?.user.email
        userID = savedSession?.user.id
        displayName = UserDefaults.standard.string(forKey: displayNameKey)
            ?? Self.friendlyDisplayName(preferredName: savedSession?.user.metadata?.displayName, email: email, provider: authProvider)
        if Self.isUnfriendlyRelayName(displayName, email: email) {
            displayName = Self.friendlyDisplayName(preferredName: savedSession?.user.metadata?.displayName, email: email, provider: authProvider)
        }

        if savedSession != nil {
            Task {
                await resumeSavedSession()
            }
        }
    }

    var statusText: String {
        isGuest ? "Misafir mod" : displayName
    }

    var needsDisplayNamePrompt: Bool {
        guard isAuthenticated else { return false }
        return Self.cleanDisplayName(displayName) == nil
            || displayName == "Kullanıcı"
            || displayName == "Apple ile giriş"
            || Self.isUnfriendlyRelayName(displayName, email: email)
    }

    var accountKindText: String {
        guard isAuthenticated else { return "Misafir" }
        switch authProvider {
        case .apple:
            return "Apple hesabı"
        case .email:
            return "E-posta hesabı"
        case .guest:
            return "Misafir"
        }
    }

    var emailLabelText: String {
        guard isAuthenticated else { return "E-posta" }
        if authProvider == .apple && Self.isApplePrivateRelay(email) {
            return "Apple gizli e-posta"
        }
        return "E-posta"
    }

    var emailDisplayText: String {
        if authProvider == .apple && Self.isApplePrivateRelay(email) {
            return "Apple tarafından gizlendi"
        }
        return email ?? "Bağlı değil"
    }

    var accountDescriptionText: String {
        isAuthenticated
            ? "Favori, kart ve kazanç kayıtlarını buluta senkronlayabilirsin."
            : "Misafir kullanım açık. Hesap bağlarsan favorilerin, kartların ve kazanç kayıtların cihazlar arasında taşınır."
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
        authProvider = .guest
        session = nil
        authMessage = nil
        plan = .free
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
        isLoading = true
        authMessage = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 160_000_000)
            continueAsGuest()
            isLoading = false
        }

        if let accessToken {
            Task.detached(priority: .utility) {
                await SupabaseAuthService().signOut(accessToken: accessToken)
            }
        }
    }

    func applyPremiumPurchasePreview() {
        plan = .premium
        authMessage = "Premium aktif edildi. Kalıcı abonelik doğrulaması yayın adımında Supabase/RevenueCat ile bağlanacak."
    }

    func resumeSavedSession() async {
        guard let session else {
            plan = .free
            return
        }

        if shouldRefresh(session), let refreshToken = session.refreshToken {
            do {
                let refreshed = try await authService.refreshSession(refreshToken: refreshToken)
                apply(session: refreshed, provider: authProvider)
            } catch {
                authMessage = "Oturum yenilenemedi. Bağlantı düzelince tekrar denenecek veya yeniden giriş yapabilirsin."
            }
        }

        await refreshProfile()
    }

    func signIn(email: String, password: String) async {
        await authenticate(email: email, password: password, isSignUp: false)
    }

    func signUp(email: String, password: String, displayName: String? = nil) async {
        await authenticate(email: email, password: password, isSignUp: true, displayName: displayName)
    }

    func signInWithApple(idToken: String, nonce: String, preferredName: String? = nil) async {
        isLoading = true
        authMessage = nil

        do {
            let newSession = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
            apply(session: newSession, provider: .apple, preferredName: preferredName)
            if let cleanName = Self.cleanDisplayName(preferredName) {
                Task {
                    try? await profileService.updateDisplayName(session: newSession, displayName: cleanName)
                }
            }
            authMessage = "Apple ile giriş başarılı."
            Task {
                await refreshProfile()
            }
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
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
        guard let token = Self.recoveryAccessToken(from: url) else {
            authMessage = "Şifre sıfırlama bağlantısı açıldı ama güvenli token okunamadı. Maildeki en son bağlantıyı Safari yerine simülatörde tekrar açmayı dene."
            return
        }
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

    func updateDisplayName(_ value: String) async {
        guard let cleanName = Self.cleanDisplayName(value) else {
            authMessage = "Ad alanı boş olamaz."
            return
        }

        displayName = cleanName
        authMessage = nil
        save()

        guard let session else { return }
        do {
            try await profileService.updateDisplayName(session: session, displayName: cleanName)
        } catch {
            authMessage = "Ad kaydedildi. Bulut senkronu bağlantı düzelince tekrar denenebilir."
        }
    }

    private func authenticate(email: String, password: String, isSignUp: Bool, displayName: String? = nil) async {
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
            apply(session: newSession, provider: .email, preferredName: displayName)
            if isSignUp, let cleanName = Self.cleanDisplayName(displayName) {
                Task {
                    try? await profileService.updateDisplayName(session: newSession, displayName: cleanName)
                }
            }
            authMessage = isSignUp ? "Hesap oluşturuldu ve giriş yapıldı." : "Giriş başarılı."
            Task {
                await refreshProfile()
            }
        } catch {
            authMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    func refreshProfile() async {
        guard let session else {
            plan = .free
            return
        }

        do {
            try await profileService.ensureProfile(session: session)
            if let profile = try await profileService.fetchProfile(session: session) {
                plan = profile.effectivePlan
                if let displayName = Self.cleanDisplayName(profile.displayName),
                   !Self.isUnfriendlyRelayName(displayName, email: email) {
                    self.displayName = displayName
                    save()
                }
            }
        } catch {
            plan = .free
        }
    }

    private func apply(session newSession: AuthSession, provider: AuthProvider = .email, preferredName: String? = nil) {
        session = newSession
        email = newSession.user.email
        userID = newSession.user.id
        authProvider = provider
        displayName = Self.friendlyDisplayName(preferredName: preferredName ?? newSession.user.metadata?.displayName, email: newSession.user.email, provider: provider)
        isGuest = false
        save()
    }

    private func shouldRefresh(_ session: AuthSession) -> Bool {
        guard let expiresAt = session.expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow < refreshLeeway
    }

    private func save() {
        UserDefaults.standard.set(displayName, forKey: displayNameKey)
        UserDefaults.standard.set(authProvider.rawValue, forKey: authProviderKey)
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
        guard type == nil || type == "recovery" || type == "signup" else { return nil }
        return allItems.first(where: { $0.name == "access_token" })?.value
            ?? allItems.first(where: { $0.name == "token" })?.value
    }

    private static func friendlyDisplayName(preferredName: String?, email: String?, provider: AuthProvider) -> String {
        if let name = cleanDisplayName(preferredName) {
            return name
        }
        if provider == .apple {
            return "Apple ile giriş"
        }
        if let email, !isApplePrivateRelay(email) {
            return email
        }
        return "Kullanıcı"
    }

    static func cleanDisplayName(_ value: String?) -> String? {
        guard let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines), !cleaned.isEmpty else {
            return nil
        }
        return cleaned
    }

    static func isApplePrivateRelay(_ email: String?) -> Bool {
        email?.lowercased().contains("@privaterelay.appleid.com") == true
    }

    private static func isUnfriendlyRelayName(_ value: String, email: String?) -> Bool {
        guard isApplePrivateRelay(email) else { return false }
        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let localPart = email?.split(separator: "@").first.map(String.init)?.lowercased()
        return normalizedValue.contains("@privaterelay.appleid.com") || normalizedValue == localPart
    }
}

enum AuthProvider: String, Codable {
    case guest
    case email
    case apple
}

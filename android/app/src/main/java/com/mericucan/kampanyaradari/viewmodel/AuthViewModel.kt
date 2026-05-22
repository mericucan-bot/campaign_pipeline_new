package com.mericucan.kampanyaradari.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.mericucan.kampanyaradari.data.remote.AuthService
import com.mericucan.kampanyaradari.data.remote.AuthSession
import com.mericucan.kampanyaradari.domain.SubscriptionPlan
import com.mericucan.kampanyaradari.store.PrefsStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AuthViewModel(application: Application) : AndroidViewModel(application) {

    private val authService = AuthService()
    val prefsStore = PrefsStore(application)

    private val _session      = MutableStateFlow<AuthSession?>(null)
    private val _isGuest      = MutableStateFlow(true)
    private val _displayName  = MutableStateFlow("Misafir")
    private val _email        = MutableStateFlow<String?>(null)
    private val _authMessage  = MutableStateFlow<String?>(null)
    private val _isLoading    = MutableStateFlow(false)
    private val _plan         = MutableStateFlow(SubscriptionPlan.FREE)

    val session: StateFlow<AuthSession?>     = _session.asStateFlow()
    val isGuest: StateFlow<Boolean>          = _isGuest.asStateFlow()
    val displayName: StateFlow<String>       = _displayName.asStateFlow()
    val email: StateFlow<String?>            = _email.asStateFlow()
    val authMessage: StateFlow<String?>      = _authMessage.asStateFlow()
    val isLoading: StateFlow<Boolean>        = _isLoading.asStateFlow()
    val plan: StateFlow<SubscriptionPlan>    = _plan.asStateFlow()

    val isAuthenticated: Boolean get() = _session.value != null && !_isGuest.value

    init {
        val saved = prefsStore.loadSession()
        if (saved != null) {
            _session.value     = saved
            _isGuest.value     = false
            _email.value       = saved.user.email
            _displayName.value = saved.user.metadata?.bestDisplayName
                ?: saved.user.email
                ?: "Kullanıcı"
            tryRefreshSession(saved)
        }
    }

    fun continueAsGuest() {
        _session.value     = null
        _isGuest.value     = true
        _displayName.value = "Misafir"
        _email.value       = null
        _authMessage.value = null
        _plan.value        = SubscriptionPlan.FREE
        prefsStore.saveSession(null)
        viewModelScope.launch { prefsStore.setIsGuest(true) }
    }

    fun signIn(email: String, password: String) {
        val cleaned = email.trim()
        if (!cleaned.contains("@") || password.length < 6) {
            _authMessage.value = "E-posta geçerli olmalı, şifre en az 6 karakter olmalı."
            return
        }
        viewModelScope.launch {
            _isLoading.value = true
            _authMessage.value = null
            runCatching {
                withContext(Dispatchers.IO) { authService.signIn(cleaned, password) }
            }.onSuccess { session ->
                applySession(session)
                _authMessage.value = "Giriş başarılı."
            }.onFailure {
                _authMessage.value = it.message ?: "Giriş başarısız."
            }
            _isLoading.value = false
        }
    }

    fun signUp(email: String, password: String, displayName: String? = null) {
        val cleaned = email.trim()
        if (!cleaned.contains("@") || password.length < 6) {
            _authMessage.value = "E-posta geçerli olmalı, şifre en az 6 karakter olmalı."
            return
        }
        viewModelScope.launch {
            _isLoading.value = true
            _authMessage.value = null
            runCatching {
                withContext(Dispatchers.IO) { authService.signUp(cleaned, password) }
            }.onSuccess { session ->
                applySession(session)
                if (!displayName.isNullOrBlank()) {
                    _displayName.value = displayName.trim()
                    viewModelScope.launch { prefsStore.setDisplayName(displayName.trim()) }
                }
                _authMessage.value = "Hesap oluşturuldu ve giriş yapıldı."
            }.onFailure { err ->
                // 📧 ile başlıyorsa email onayı mesajıdır, hata değil bilgi
                _authMessage.value = err.message ?: "Kayıt başarısız."
            }
            _isLoading.value = false
        }
    }

    fun sendPasswordReset(email: String) {
        val cleaned = email.trim()
        if (!cleaned.contains("@")) {
            _authMessage.value = "Geçerli bir e-posta adresi gir."
            return
        }
        viewModelScope.launch {
            _isLoading.value = true
            runCatching {
                withContext(Dispatchers.IO) { authService.sendPasswordReset(cleaned) }
            }.onSuccess {
                _authMessage.value = "Şifre sıfırlama maili gönderildi. Mail kutunu kontrol et."
            }.onFailure {
                _authMessage.value = it.message ?: "Mail gönderilemedi."
            }
            _isLoading.value = false
        }
    }

    fun signOut() {
        val token = _session.value?.accessToken
        continueAsGuest()
        token?.let { t ->
            viewModelScope.launch(Dispatchers.IO) {
                runCatching { authService.signOut(t) }
            }
        }
    }

    fun clearMessage() { _authMessage.value = null }

    // ── Private helpers ───────────────────────────────────────

    private fun applySession(session: AuthSession) {
        _session.value     = session
        _isGuest.value     = false
        _email.value       = session.user.email
        _displayName.value = session.user.metadata?.bestDisplayName
            ?: session.user.email
            ?: "Kullanıcı"
        prefsStore.saveSession(session)
        viewModelScope.launch {
            prefsStore.setIsGuest(false)
            prefsStore.setDisplayName(_displayName.value)
        }
    }

    private fun tryRefreshSession(session: AuthSession) {
        val refreshToken = session.refreshToken ?: return
        val expiresAt    = session.expiresAt
        // expiresAt null ise süre bilinmiyor → her zaman refresh dene
        // Biliniyorsa: 5 dakika veya daha az kaldıysa refresh yap
        val needsRefresh = expiresAt == null ||
                (expiresAt - System.currentTimeMillis() / 1000) < 5 * 60L
        if (!needsRefresh) return
        viewModelScope.launch(Dispatchers.IO) {
            runCatching { authService.refreshSession(refreshToken) }
                .onSuccess { newSession ->
                    withContext(Dispatchers.Main) { applySession(newSession) }
                }
                .onFailure {
                    // Refresh token da geçersiz (süresi dolmuş) → misafir moduna geç
                    withContext(Dispatchers.Main) { continueAsGuest() }
                }
        }
    }
}

package com.mericucan.kampanyaradari.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.mericucan.kampanyaradari.data.remote.AuthSession
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.appDataStore: DataStore<Preferences> by preferencesDataStore("app_prefs")

class PrefsStore(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private val ONBOARDING_SEEN  = booleanPreferencesKey("onboarding_seen")
    private val DISPLAY_NAME     = stringPreferencesKey("display_name")
    private val IS_GUEST         = booleanPreferencesKey("is_guest")

    val onboardingSeen: Flow<Boolean> = context.appDataStore.data.map { it[ONBOARDING_SEEN] ?: false }
    val isGuest: Flow<Boolean>        = context.appDataStore.data.map { it[IS_GUEST] ?: true }
    val displayName: Flow<String>     = context.appDataStore.data.map { it[DISPLAY_NAME] ?: "Misafir" }

    // Session stored in regular SharedPreferences (plain — upgrade to EncryptedSharedPreferences in prod)
    fun loadSession(): AuthSession? {
        return try {
            val raw = context.getSharedPreferences("kr_session", Context.MODE_PRIVATE)
                .getString("session", null) ?: return null
            json.decodeFromString<AuthSession>(raw)
        } catch (e: Exception) { null }
    }

    fun saveSession(session: AuthSession?) {
        val sp = context.getSharedPreferences("kr_session", Context.MODE_PRIVATE).edit()
        if (session == null) sp.remove("session") else sp.putString("session", json.encodeToString(session))
        sp.apply()
    }

    suspend fun setOnboardingSeen(seen: Boolean) {
        context.appDataStore.edit { it[ONBOARDING_SEEN] = seen }
    }

    suspend fun setDisplayName(name: String) {
        context.appDataStore.edit { it[DISPLAY_NAME] = name }
    }

    suspend fun setIsGuest(guest: Boolean) {
        context.appDataStore.edit { it[IS_GUEST] = guest }
    }
}

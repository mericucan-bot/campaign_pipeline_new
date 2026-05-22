package com.mericucan.kampanyaradari.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.trackingDataStore: DataStore<Preferences>
        by preferencesDataStore("campaign_tracking")

/** Tek kampanyaya ait takip verisi. */
data class TrackingState(
    val isTracking: Boolean      = false,
    val spentText: String        = "0",
    val earnedText: String       = "0",
    val reminderEnabled: Boolean = false,
    /** ISO-8601 tarih (YYYY-MM-DD). Boşsa henüz seçilmedi. */
    val reminderDateText: String = ""
)

/**
 * Kampanya başına harcama/kazanç takibi ve hatırlatıcı verisini
 * DataStore'da saklar. Her alan campaign id'ye göre ayrı key taşır.
 */
class CampaignTrackingStore(private val context: Context) {

    fun stateFor(campaignId: String): Flow<TrackingState> =
        context.trackingDataStore.data.map { prefs ->
            TrackingState(
                isTracking       = prefs[booleanPreferencesKey("tracking_$campaignId")]      ?: false,
                spentText        = prefs[stringPreferencesKey("spent_$campaignId")]           ?: "0",
                earnedText       = prefs[stringPreferencesKey("earned_$campaignId")]          ?: "0",
                reminderEnabled  = prefs[booleanPreferencesKey("reminder_$campaignId")]       ?: false,
                reminderDateText = prefs[stringPreferencesKey("reminder_date_$campaignId")]   ?: ""
            )
        }

    suspend fun setTracking(campaignId: String, value: Boolean) {
        context.trackingDataStore.edit {
            it[booleanPreferencesKey("tracking_$campaignId")] = value
            // Takip kapanınca hatırlatıcıyı da kapat
            if (!value) it[booleanPreferencesKey("reminder_$campaignId")] = false
        }
    }

    suspend fun setSpent(campaignId: String, text: String) {
        context.trackingDataStore.edit { it[stringPreferencesKey("spent_$campaignId")] = text }
    }

    suspend fun setEarned(campaignId: String, text: String) {
        context.trackingDataStore.edit { it[stringPreferencesKey("earned_$campaignId")] = text }
    }

    suspend fun setReminder(campaignId: String, value: Boolean) {
        context.trackingDataStore.edit { it[booleanPreferencesKey("reminder_$campaignId")] = value }
    }

    suspend fun setReminderDate(campaignId: String, dateText: String) {
        context.trackingDataStore.edit {
            it[stringPreferencesKey("reminder_date_$campaignId")] = dateText
        }
    }

    suspend fun clearReminder(campaignId: String) {
        context.trackingDataStore.edit {
            it[booleanPreferencesKey("reminder_$campaignId")]     = false
            it[stringPreferencesKey("reminder_date_$campaignId")] = ""
        }
    }

    /** Tüm kampanyaların takip verilerini campaignId → state olarak döner. */
    val allStates: Flow<Map<String, TrackingState>> =
        context.trackingDataStore.data.map { prefs ->
            // Anahtar prefix'lerini ayıklayarak campaignId kümesi çıkar.
            // NOT: "reminder_date_" prefix'i "reminder_" ile çakıştığı için ÖNCE kontrol edilmeli.
            val ids = mutableSetOf<String>()
            prefs.asMap().keys.forEach { key ->
                val name = key.name
                when {
                    name.startsWith("reminder_date_") -> ids += name.removePrefix("reminder_date_")
                    name.startsWith("tracking_")      -> ids += name.removePrefix("tracking_")
                    name.startsWith("spent_")         -> ids += name.removePrefix("spent_")
                    name.startsWith("earned_")        -> ids += name.removePrefix("earned_")
                    name.startsWith("reminder_")      -> ids += name.removePrefix("reminder_")
                }
            }
            ids.associateWith { id ->
                TrackingState(
                    isTracking       = prefs[booleanPreferencesKey("tracking_$id")]    ?: false,
                    spentText        = prefs[stringPreferencesKey("spent_$id")]         ?: "0",
                    earnedText       = prefs[stringPreferencesKey("earned_$id")]        ?: "0",
                    reminderEnabled  = prefs[booleanPreferencesKey("reminder_$id")]     ?: false,
                    reminderDateText = prefs[stringPreferencesKey("reminder_date_$id")] ?: ""
                )
            }
        }

    /** Tüm takip verilerini ve hatırlatıcıları temizler. */
    suspend fun removeAll() {
        context.trackingDataStore.edit { it.clear() }
    }
}

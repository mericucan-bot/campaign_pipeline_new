package com.mericucan.kampanyaradari.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.myCardsDataStore: DataStore<Preferences> by preferencesDataStore("my_cards")

class MyCardsStore(private val context: Context) {
    private val BANKS_KEY = stringSetPreferencesKey("card_banks")

    /** Kullanıcının kaydettiği banka adları */
    val banks: Flow<Set<String>> = context.myCardsDataStore.data
        .map { it[BANKS_KEY] ?: emptySet() }

    /** Bankayı toggle eder (ekle / çıkar) */
    suspend fun toggle(bank: String) {
        context.myCardsDataStore.edit { prefs ->
            val current = prefs[BANKS_KEY] ?: emptySet()
            prefs[BANKS_KEY] = if (bank in current) current - bank else current + bank
        }
    }

    /** Tüm kartları temizler */
    suspend fun clear() {
        context.myCardsDataStore.edit { it.remove(BANKS_KEY) }
    }
}

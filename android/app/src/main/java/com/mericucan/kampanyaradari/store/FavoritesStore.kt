package com.mericucan.kampanyaradari.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.favDataStore: DataStore<Preferences> by preferencesDataStore("favorites")

class FavoritesStore(private val context: Context) {
    private val KEY = stringSetPreferencesKey("favorite_ids")

    val ids: Flow<Set<String>> = context.favDataStore.data.map { it[KEY] ?: emptySet() }

    suspend fun toggle(id: String) {
        context.favDataStore.edit { prefs ->
            val current = prefs[KEY] ?: emptySet()
            prefs[KEY] = if (current.contains(id)) current - id else current + id
        }
    }

    suspend fun add(id: String) {
        context.favDataStore.edit { prefs ->
            prefs[KEY] = (prefs[KEY] ?: emptySet()) + id
        }
    }

    suspend fun remove(id: String) {
        context.favDataStore.edit { prefs ->
            prefs[KEY] = (prefs[KEY] ?: emptySet()) - id
        }
    }

    suspend fun removeAll() {
        context.favDataStore.edit { prefs -> prefs[KEY] = emptySet() }
    }
}

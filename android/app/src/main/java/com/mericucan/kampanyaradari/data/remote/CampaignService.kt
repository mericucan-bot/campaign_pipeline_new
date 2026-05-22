package com.mericucan.kampanyaradari.data.remote

import com.mericucan.kampanyaradari.data.model.Campaign
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

class CampaignService {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }
    private val pageSize = 1000

    suspend fun fetchActiveCampaigns(): List<Campaign> = withContext(Dispatchers.IO) {
        val all = mutableListOf<Campaign>()
        var offset = 0
        while (true) {
            val page = fetchPage(offset)
            all.addAll(page)
            if (page.size < pageSize) break
            offset += pageSize
        }
        all.filter { it.isCurrentOrUndated && it.isDisplayable }
    }

    private fun fetchPage(offset: Int): List<Campaign> {
        val fields = listOf(
            "id", "bank", "bank_label", "title", "summary", "description",
            "image_url", "source_url", "category", "reward_type",
            "reward_value", "valid_to", "opportunity_score", "is_active"
        ).joinToString(",")

        val url = "${SupabaseConfig.URL}/rest/v1/campaigns" +
                "?select=$fields" +
                "&is_active=eq.true" +
                "&order=valid_to.asc.nullslast"

        val request = Request.Builder()
            .url(url)
            .addHeader("apikey", SupabaseConfig.ANON_KEY)
            .addHeader("Authorization", "Bearer ${SupabaseConfig.ANON_KEY}")
            .addHeader("Range-Unit", "items")
            .addHeader("Range", "$offset-${offset + pageSize - 1}")
            .get()
            .build()

        val response = client.newCall(request).execute()
        val body = response.use { r ->
            if (!r.isSuccessful) throw Exception("Sunucu hatası: ${r.code}")
            r.body?.string()
        } ?: return emptyList()
        return runCatching { json.decodeFromString<List<Campaign>>(body) }.getOrElse { emptyList() }
    }
}

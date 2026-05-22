package com.mericucan.kampanyaradari.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

@Serializable
data class Campaign(
    val id: String,
    val bank: String,
    @SerialName("bank_label") val bankLabel: String? = null,
    val title: String,
    val summary: String? = null,
    val description: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("source_url") val sourceUrl: String? = null,
    val category: String? = null,
    @SerialName("reward_type") val rewardType: String? = null,
    @SerialName("reward_value") val rewardValue: Double? = null,
    @SerialName("valid_to") val validTo: String? = null,
    @SerialName("opportunity_score") val opportunityScore: Int? = null,
    @SerialName("is_active") val isActive: Boolean = true
) {
    val displayBank: String
        get() {
            val label = bankLabel?.trim()
            val source = if (!label.isNullOrEmpty()) label else bank
            val normalized = source.lowercase()
                .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
                .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
            return if (normalized == "ykb" || normalized.contains("yapi kredi") || normalized.contains("yapikredi")) {
                "Yapı Kredi"
            } else source
        }

    val displaySummary: String
        get() {
            if (!summary.isNullOrEmpty()) return summary
            if (!description.isNullOrEmpty()) return description
            return "Detaylar kaynak sayfada."
        }

    val validToDate: LocalDate?
        get() = validTo?.let {
            try { LocalDate.parse(it.take(10), DateTimeFormatter.ISO_LOCAL_DATE) }
            catch (e: Exception) { null }
        }

    val deadlineText: String
        get() {
            val date = validToDate ?: return "Tarih kaynakta"
            val today = LocalDate.now()
            val days = ChronoUnit.DAYS.between(today, date)
            return when {
                days < 0  -> "Süresi geçmiş"
                days == 0L -> "Bugün bitiyor"
                days <= 7  -> "Son $days gün"
                else       -> date.format(DateTimeFormatter.ofPattern("d MMM yyyy"))
            }
        }

    val isUrgent: Boolean
        get() {
            val date = validToDate ?: return false
            return ChronoUnit.DAYS.between(LocalDate.now(), date) in 0..7
        }

    val isCurrentOrUndated: Boolean
        get() {
            val date = validToDate ?: return true
            return !date.isBefore(LocalDate.now())
        }

    /**
     * Ödül değerini akıllıca biçimlendirip döndürür.
     * Nakit İade/büyük değerler → "X TL", Puan → "X Puan",
     * Taksit → "X Taksit", küçük indirimler → "%X"
     */
    val rewardDisplayValue: String
        get() {
            val value = rewardValue ?: return ""
            if (value <= 0) return ""
            val type = rewardType ?: ""
            val t = type.lowercase()
                .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
                .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
            val intVal = value.toInt()
            return when {
                t.contains("nakit") || t.contains("iade") || t.contains("cashback") -> "$intVal TL"
                t.contains("puan") || t.contains("milmil") || t.contains("bonus") || t.contains("avantaj") -> "$intVal Puan"
                t.contains("taksit") -> "$intVal Taksit"
                value > 100 -> "$intVal TL"   // Büyük değer = TL tutarı, % değil
                else -> "%$intVal"
            }
        }

    val isDisplayable: Boolean
        get() {
            if (title.trim().length <= 2) return false
            val normalized = title.lowercase()
                .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
                .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
            val blocked = setOf("70 giyim", "8 yurt disi alisverisi", "8 yurtdisi alisverisi")
            return !blocked.contains(normalized)
        }
}

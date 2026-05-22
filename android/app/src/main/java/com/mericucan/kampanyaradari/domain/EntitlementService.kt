package com.mericucan.kampanyaradari.domain

enum class SubscriptionPlan {
    FREE, TRIAL, PREMIUM;

    val isPremiumLike get() = this == TRIAL || this == PREMIUM
    val displayName get() = when (this) {
        FREE    -> "Free"
        TRIAL   -> "Deneme"
        PREMIUM -> "Premium"
    }
}

data class EntitlementRule(val allowed: Boolean, val title: String, val message: String)

object EntitlementService {
    const val FREE_FAVORITE_LIMIT = 3
    const val FREE_REMINDER_LIMIT = 1

    fun canAddFavorite(
        plan: SubscriptionPlan,
        favoriteIds: Set<String>,
        campaignId: String,
        isGuest: Boolean
    ): EntitlementRule {
        if (isGuest) return EntitlementRule(
            false, "Giriş gerekli",
            "Favorileri kaydetmek için hesap oluşturman veya giriş yapman gerekiyor."
        )
        if (plan.isPremiumLike) return EntitlementRule(true, "", "")
        if (favoriteIds.contains(campaignId)) return EntitlementRule(true, "", "") // kaldırmaya izin ver
        if (favoriteIds.size < FREE_FAVORITE_LIMIT) return EntitlementRule(true, "", "")
        return EntitlementRule(
            false, "Favori limitine ulaştın",
            "Free planda $FREE_FAVORITE_LIMIT favori kampanya saklayabilirsin. Premium ile sınırsız favori ekleyebilirsin."
        )
    }

    fun favoriteAllowanceText(plan: SubscriptionPlan, count: Int): String {
        if (plan.isPremiumLike) return "Sınırsız favori"
        return "${minOf(count, FREE_FAVORITE_LIMIT)}/$FREE_FAVORITE_LIMIT favori"
    }

    fun reminderAllowanceText(plan: SubscriptionPlan, activeReminderCount: Int): String {
        if (plan.isPremiumLike) return "Öncelikli hatırlatıcı"
        return "${minOf(activeReminderCount, FREE_REMINDER_LIMIT)}/$FREE_REMINDER_LIMIT aktif hatırlatıcı"
    }

    fun canTrackCampaign(isGuest: Boolean): EntitlementRule {
        if (isGuest) return EntitlementRule(
            false, "Giriş gerekli",
            "Kampanya takibini açmak için hesap oluşturman veya giriş yapman gerekiyor."
        )
        return EntitlementRule(true, "", "")
    }

    fun canUseReminder(
        plan: SubscriptionPlan,
        activeReminderCount: Int,
        isGuest: Boolean
    ): EntitlementRule {
        if (isGuest) return EntitlementRule(
            false, "Giriş gerekli",
            "Hatırlatıcı eklemek için hesap oluşturman veya giriş yapman gerekiyor."
        )
        if (plan.isPremiumLike) return EntitlementRule(true, "Premium hatırlatıcı", "")
        if (activeReminderCount < FREE_REMINDER_LIMIT) return EntitlementRule(true, "Ücretsiz hatırlatıcı", "")
        return EntitlementRule(
            false, "Premium ile öncelikli takip",
            "Free planda 1 aktif hatırlatıcı hakkın var. Premium ile sınırsız hatırlatıcı ekleyebilirsin."
        )
    }
}

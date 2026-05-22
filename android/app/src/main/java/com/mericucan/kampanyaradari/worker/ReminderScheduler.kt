package com.mericucan.kampanyaradari.worker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.work.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit

/**
 * Puan son kullanma tarihine göre 3 hatırlatıcı zamanlar:
 *  • 7 gün önce (sabah 09:00)
 *  • 3 gün önce (sabah 09:00)
 *  • Son gün  (sabah 09:00)
 *
 * Her kampanya kendi tag'ine göre iptal edilebilir.
 */
object ReminderScheduler {

    const val CHANNEL_ID = "campaign_reminders"

    /** Uygulama başlarken çağrılır. Kanal zaten varsa etkisizdir. */
    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kampanya Hatırlatıcıları",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Puan son kullanma tarihine yaklaşınca bildirim gönderir."
            }
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    /**
     * Verilen [expiryDate] için 3 WorkManager görevi planlar.
     * Geçmişteki tarihler için görev oluşturulmaz.
     */
    fun schedule(
        context: Context,
        campaignId: String,
        campaignTitle: String,
        expiryDate: LocalDate
    ) {
        cancelAll(context, campaignId)

        val now = LocalDateTime.now()

        // 7 gün önce, 3 gün önce, son gün
        listOf(7, 3, 0).forEach { daysBeforeExpiry ->
            val reminderDay  = expiryDate.minusDays(daysBeforeExpiry.toLong())
            val reminderTime = reminderDay.atTime(9, 0)          // Sabah 09:00
            val delayMs      = ChronoUnit.MILLIS.between(now, reminderTime)

            if (delayMs > 0) {
                val inputData = workDataOf(
                    "campaign_title" to campaignTitle,
                    "days_left"      to daysBeforeExpiry
                )
                val request = OneTimeWorkRequestBuilder<ReminderWorker>()
                    .setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
                    .setInputData(inputData)
                    .addTag(tagFor(campaignId))
                    .build()

                WorkManager.getInstance(context).enqueue(request)
            }
        }
    }

    /** Belirli bir kampanyanın tüm bekleyen hatırlatıcılarını iptal eder. */
    fun cancelAll(context: Context, campaignId: String) {
        WorkManager.getInstance(context).cancelAllWorkByTag(tagFor(campaignId))
    }

    private fun tagFor(campaignId: String) = "reminder_$campaignId"
}

package com.mericucan.kampanyaradari.worker

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.mericucan.kampanyaradari.MainActivity
import com.mericucan.kampanyaradari.R

/**
 * Arka planda çalışan bildirim gönderici.
 * WorkManager tarafından zamanlanmış gecikmelerle tetiklenir.
 *
 * Input data keys:
 *  - "campaign_title" : String   → kampanya adı
 *  - "days_left"      : Int      → kaç gün kaldı (0 = son gün, 7 veya 3)
 */
class ReminderWorker(
    private val ctx: Context,
    params: WorkerParameters
) : Worker(ctx, params) {

    override fun doWork(): Result {
        val title    = inputData.getString("campaign_title") ?: return Result.failure()
        val daysLeft = inputData.getInt("days_left", -1)

        val bodyText = when (daysLeft) {
            0    -> "\"$title\" puanlarınızın son kullanma tarihi bugün! Harcamayı unutmayın. ⏰"
            1    -> "\"$title\" puanlarınızın son kullanma tarihi yarın!"
            else -> "\"$title\" puanlarınızın son kullanma tarihine $daysLeft gün kaldı."
        }

        // Uygulamayı açmak için tap intent
        val tapIntent = Intent(ctx, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(
            ctx, title.hashCode(),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(ctx, ReminderScheduler.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_bell)
            .setContentTitle("Kampanya Hatırlatıcı 🔔")
            .setContentText(bodyText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bodyText))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        // notifyId: farklı bildirimler için benzersiz ID
        val notifId = (title.hashCode() xor daysLeft) and Int.MAX_VALUE
        NotificationManagerCompat.from(ctx).notify(notifId, notification)

        return Result.success()
    }
}

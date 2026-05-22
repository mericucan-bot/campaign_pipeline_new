package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mericucan.kampanyaradari.domain.SubscriptionPlan
import com.mericucan.kampanyaradari.ui.theme.*

/**
 * Premium satın alma sheet'i — iOS sürümünden referans alınarak yazıldı.
 *
 * Şu an gerçek Google Play Billing entegrasyonu yok; "Premium'a yükselt"
 * butonu yalnızca sheet'i kapatır. Billing eklendiğinde [onSubscribe] üzerinden
 * seçili plan ile satın alma akışı tetiklenebilir.
 */
@Composable
fun PremiumSheet(
    currentPlan: SubscriptionPlan,
    onDismiss: () -> Unit,
    onSubscribe: (PremiumOption) -> Unit = {}
) {
    var selected by remember { mutableStateOf(PremiumOption.YEARLY) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(top = 4.dp, bottom = 28.dp)
            .navigationBarsPadding(),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // ── Başlık + kapat ────────────────────────────────────────
        Row(
            modifier              = Modifier.fillMaxWidth(),
            verticalAlignment     = Alignment.Top,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    "Kampanya",
                    fontSize   = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    lineHeight = 36.sp
                )
                Text(
                    "Radarı Premium",
                    fontSize   = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    lineHeight = 36.sp
                )
                Spacer(Modifier.height(10.dp))
                Text(
                    "Kartına özel kampanya alarmı, sınırsız favori ve sınırsız hatırlatıcı.",
                    fontSize   = 14.sp,
                    color      = TextPrimary.copy(alpha = 0.72f),
                    lineHeight = 20.sp
                )
            }
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(PanelBlack)
                    .border(1.dp, BorderSubtle, CircleShape)
                    .clickable { onDismiss() },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Filled.Close, "Kapat", tint = TextPrimary, modifier = Modifier.size(18.dp))
            }
        }

        // ── Özellik listesi ────────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PremiumFeatureRow(
                icon     = Icons.Filled.NotificationsActive,
                title    = "Kartıma özel yeni kampanya alarmı",
                subtitle = "Kartlarımda kayıtlı bankalar için yeni kampanya çıktığında bildirim alırsın."
            )
            PremiumFeatureRow(
                icon     = Icons.Filled.Star,
                title    = "Sınırsız favori",
                subtitle = "Free planda 3 favori hakkın var. Premium ile sınırsız kampanya kaydet."
            )
            PremiumFeatureRow(
                icon     = Icons.Filled.NotificationsActive,
                title    = "Sınırsız hatırlatıcı",
                subtitle = "Birden fazla kampanya için puan son kullanım bildirimleri."
            )
            PremiumFeatureRow(
                icon     = Icons.AutoMirrored.Filled.TrendingUp,
                title    = "Gelişmiş kazanç takibi",
                subtitle = "Harcama, kazanım ve net faydayı takip et."
            )
        }

        // ── Plan tile'ları ─────────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PremiumPlanTile(
                icon        = Icons.Filled.CalendarMonth,
                title       = "Aylık Premium",
                subtitle    = "Esnek deneme için aylık plan",
                price       = "$0.99",
                statusLabel = "Hazır",
                isSelected  = selected == PremiumOption.MONTHLY,
                showBadge   = false,
                onClick     = { selected = PremiumOption.MONTHLY }
            )
            PremiumPlanTile(
                icon        = Icons.Filled.AutoAwesome,
                title       = "Yıllık Premium",
                subtitle    = "Daha uygun uzun dönem plan",
                price       = "$6.99",
                statusLabel = "Hazır",
                isSelected  = selected == PremiumOption.YEARLY,
                showBadge   = true,
                onClick     = { selected = PremiumOption.YEARLY }
            )
        }

        // ── Mevcut plan kartı ──────────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(18.dp))
                .background(Color.White.copy(alpha = 0.06f))
                .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(18.dp))
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                "Mevcut plan",
                fontSize   = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color      = TextPrimary.copy(alpha = 0.58f)
            )
            Text(
                currentPlan.displayName,
                fontSize   = 22.sp,
                fontWeight = FontWeight.Bold,
                color      = if (currentPlan.isPremiumLike) DashboardGreen else DashboardGreen
            )
        }

        // ── CTA: Premium'a yükselt ─────────────────────────────────
        Button(
            onClick  = {
                onSubscribe(selected)
                onDismiss()
            },
            enabled  = !currentPlan.isPremiumLike,
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape    = RoundedCornerShape(18.dp),
            colors   = ButtonDefaults.buttonColors(
                containerColor         = DashboardGreen,
                contentColor           = NearBlack,
                disabledContainerColor = DashboardGreen.copy(alpha = 0.35f),
                disabledContentColor   = NearBlack.copy(alpha = 0.55f)
            )
        ) {
            Icon(Icons.Filled.AutoAwesome, null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                if (currentPlan.isPremiumLike) "Premium aktif" else "Premium'a yükselt",
                fontSize   = 15.sp,
                fontWeight = FontWeight.ExtraBold
            )
        }

        // ── Yasal bilgi ────────────────────────────────────────────
        Text(
            "Premium aboneliği Google Play üzerinden yönetilir. Ödeme ve iptal işlemleri için Google Play hesabını kullan.",
            fontSize   = 11.sp,
            color      = TextPrimary.copy(alpha = 0.5f),
            lineHeight = 15.sp
        )
    }
}

enum class PremiumOption { MONTHLY, YEARLY }

// ── Yardımcı bileşenler ─────────────────────────────────────────

@Composable
private fun PremiumFeatureRow(
    icon: ImageVector,
    title: String,
    subtitle: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(18.dp))
            .padding(14.dp),
        verticalAlignment     = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(DashboardGreen.copy(alpha = 0.16f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = DashboardGreen, modifier = Modifier.size(20.dp))
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                fontSize   = 15.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary
            )
            Spacer(Modifier.height(2.dp))
            Text(
                subtitle,
                fontSize   = 12.sp,
                color      = TextPrimary.copy(alpha = 0.68f),
                lineHeight = 17.sp
            )
        }
    }
}

@Composable
private fun PremiumPlanTile(
    icon: ImageVector,
    title: String,
    subtitle: String,
    price: String,
    statusLabel: String,
    isSelected: Boolean,
    showBadge: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(
                if (isSelected) DashboardGreen.copy(alpha = 0.14f)
                else Color.White.copy(alpha = 0.06f)
            )
            .border(
                1.dp,
                if (isSelected) DashboardGreen.copy(alpha = 0.55f)
                else Color.White.copy(alpha = 0.10f),
                RoundedCornerShape(18.dp)
            )
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(DashboardGreen.copy(alpha = 0.16f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = DashboardGreen, modifier = Modifier.size(20.dp))
        }

        Column(modifier = Modifier.weight(1f)) {
            Row(
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    title,
                    fontSize   = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary
                )
                if (showBadge) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(DashboardGreen)
                            .padding(horizontal = 8.dp, vertical = 2.dp)
                    ) {
                        Text(
                            "Avantajlı",
                            fontSize   = 10.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color      = NearBlack
                        )
                    }
                }
            }
            Spacer(Modifier.height(2.dp))
            Text(
                subtitle,
                fontSize   = 12.sp,
                color      = TextPrimary.copy(alpha = 0.66f),
                lineHeight = 16.sp
            )
        }

        Column(horizontalAlignment = Alignment.End) {
            Text(
                price,
                fontSize   = 17.sp,
                fontWeight = FontWeight.ExtraBold,
                color      = TextPrimary
            )
            Spacer(Modifier.height(2.dp))
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .clip(CircleShape)
                        .background(DashboardGreen),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.Check,
                        null,
                        tint     = NearBlack,
                        modifier = Modifier.size(14.dp)
                    )
                }
            } else {
                Text(
                    statusLabel,
                    fontSize   = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = DashboardGreen
                )
            }
        }
    }
}

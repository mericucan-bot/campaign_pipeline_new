package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.store.TrackingState
import com.mericucan.kampanyaradari.ui.theme.*
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

// ── Public ekran ────────────────────────────────────────────────

@Composable
fun EarningsScreen(
    campaigns: List<Campaign>,
    trackingStates: Map<String, TrackingState>,
    onBack: () -> Unit,
    onCampaignClick: (Campaign) -> Unit,
    onClearAllTracking: () -> Unit
) {
    // ── Veri özetleri ──────────────────────────────────────────
    val tracked = remember(campaigns, trackingStates) {
        campaigns.mapNotNull { c ->
            val s = trackingStates[c.id] ?: return@mapNotNull null
            if (s.isTracking) c to s else null
        }.sortedWith(compareBy({ !it.second.isTracking }, { it.first.title.lowercase() }))
    }

    val reminders = remember(campaigns, trackingStates) {
        campaigns.mapNotNull { c ->
            val s = trackingStates[c.id] ?: return@mapNotNull null
            if (s.reminderEnabled) c to s else null
        }.sortedBy { it.first.title.lowercase() }
    }

    val joinedCount  = tracked.size
    val totalSpent   = tracked.sumOf { (it.second.spentText.toDoubleOrNull() ?: 0.0) }
    val totalEarned  = tracked.sumOf { (it.second.earnedText.toDoubleOrNull() ?: 0.0) }
    val rateText     = remember(totalSpent, totalEarned) { rewardRateText(totalSpent, totalEarned) }

    var showClearDialog by remember { mutableStateOf(false) }

    Scaffold(containerColor = NearBlack) { padding ->
        LazyColumn(
            modifier            = Modifier.fillMaxSize().padding(padding),
            contentPadding      = PaddingValues(horizontal = 22.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // ── Geri butonu ────────────────────────────────────
            item {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.08f))
                        .border(1.dp, Color.White.copy(alpha = 0.1f), CircleShape)
                        .clickable { onBack() },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Geri",
                        tint     = TextPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            // ── Başlık ─────────────────────────────────────────
            item {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        "Hesaplayıcı",
                        fontSize   = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color      = DashboardGreen
                    )
                    Text(
                        "Kazançlarım",
                        fontSize   = 32.sp,
                        fontWeight = FontWeight.Black,
                        color      = TextPrimary,
                        lineHeight = 36.sp
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "Katıldığın kampanyaları, harcamalarını ve kazançlarını tek ekranda takip et.",
                        fontSize   = 14.sp,
                        color      = TextPrimary.copy(alpha = 0.76f),
                        lineHeight = 20.sp
                    )
                }
            }

            // ── Özet kartı ─────────────────────────────────────
            item {
                EarningsSummaryCard(
                    rateText    = rateText,
                    joinedCount = joinedCount,
                    totalSpent  = totalSpent,
                    totalEarned = totalEarned
                )
            }

            // ── Hatırlatıcılarım ───────────────────────────────
            item {
                RemindersSection(
                    reminders       = reminders,
                    onCampaignClick = onCampaignClick
                )
            }

            // ── Takip edilen kampanyalar başlığı + temizle ─────
            item {
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Text(
                        "Takip edilen\nkampanyalar",
                        fontSize   = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color      = TextPrimary,
                        lineHeight = 24.sp
                    )
                    if (tracked.isNotEmpty()) {
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(999.dp))
                                .background(DashboardGreen.copy(alpha = 0.14f))
                                .clickable { showClearDialog = true }
                                .padding(horizontal = 14.dp, vertical = 10.dp),
                            verticalAlignment     = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(
                                Icons.Outlined.Delete,
                                null,
                                tint     = DashboardGreen,
                                modifier = Modifier.size(15.dp)
                            )
                            Text(
                                "Takiptekileri temizle",
                                fontSize   = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color      = DashboardGreen
                            )
                        }
                    }
                }
            }

            // ── Takip edilen kampanya listesi ──────────────────
            if (tracked.isEmpty()) {
                item { EmptyTrackedCard() }
            } else {
                items(tracked, key = { it.first.id }) { (campaign, state) ->
                    EarningsCampaignRow(
                        campaign = campaign,
                        state    = state,
                        onClick  = { onCampaignClick(campaign) }
                    )
                }
            }

            item { Spacer(Modifier.height(20.dp)) }
        }
    }

    // ── Onay diyaloğu ──────────────────────────────────────────
    if (showClearDialog) {
        Dialog(onDismissRequest = { showClearDialog = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(PanelBlack)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .background(DashboardGreen.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.Delete,
                        null,
                        tint     = DashboardGreen,
                        modifier = Modifier.size(32.dp)
                    )
                }
                Text("Takipleri Temizle", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text(
                    "${tracked.size} kampanya takipten çıkarılacak. Hatırlatıcılar da iptal edilecek.",
                    fontSize  = 14.sp,
                    color     = TextSecondary,
                    textAlign = TextAlign.Center,
                    lineHeight = 19.sp
                )
                Button(
                    onClick = {
                        onClearAllTracking()
                        showClearDialog = false
                    },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Text("Tümünü Temizle", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                }
                Button(
                    onClick = { showClearDialog = false },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = NearBlack,
                        contentColor   = TextPrimary
                    )
                ) {
                    Text("Vazgeç", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                }
            }
        }
    }
}

// ── Özet kartı ──────────────────────────────────────────────────

@Composable
private fun EarningsSummaryCard(
    rateText: String,
    joinedCount: Int,
    totalSpent: Double,
    totalEarned: Double
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(DashboardGreen.copy(alpha = 0.14f))
            .border(1.dp, Color.White.copy(alpha = 0.14f), RoundedCornerShape(24.dp))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Özet", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Spacer(Modifier.height(4.dp))
                Text(
                    "Harcadığın tutara göre geri kazanım oranı",
                    fontSize   = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = TextPrimary.copy(alpha = 0.62f),
                    lineHeight = 16.sp
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(rateText, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = DashboardGreen)
                Text(
                    "geri kazanım",
                    fontSize   = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = TextPrimary.copy(alpha = 0.62f)
                )
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DarkStatTile(modifier = Modifier.weight(1f), title = "Katılım", value = "$joinedCount")
            DarkStatTile(modifier = Modifier.weight(1f), title = "Harcama", value = totalSpent.currencyText())
            DarkStatTile(modifier = Modifier.weight(1f), title = "Kazanç", value = totalEarned.currencyText())
        }
    }
}

// ── Hatırlatıcılar bölümü ───────────────────────────────────────

@Composable
private fun RemindersSection(
    reminders: List<Pair<Campaign, TrackingState>>,
    onCampaignClick: (Campaign) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(DashboardGreen.copy(alpha = 0.12f))
            .border(1.dp, DashboardGreen.copy(alpha = 0.24f), RoundedCornerShape(24.dp))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Hatırlatıcılarım", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Spacer(Modifier.height(4.dp))
                Text(
                    "${reminders.size} aktif puan hatırlatıcısı",
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = TextPrimary.copy(alpha = 0.62f)
                )
            }
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(DashboardGreen.copy(alpha = 0.18f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Filled.Notifications,
                    null,
                    tint     = DashboardGreen,
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        if (reminders.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(Color.White.copy(alpha = 0.07f))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Aktif hatırlatıcı yok", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text(
                    "Bir kampanya detayında Katıldım ve puan son kullanım hatırlatıcısını açınca burada listelenecek.",
                    fontSize   = 13.sp,
                    color      = TextPrimary.copy(alpha = 0.66f),
                    lineHeight = 18.sp
                )
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                reminders.forEach { (campaign, state) ->
                    ReminderCampaignRow(
                        campaign = campaign,
                        state    = state,
                        onClick  = { onCampaignClick(campaign) }
                    )
                }
            }
        }
    }
}

@Composable
private fun ReminderCampaignRow(
    campaign: Campaign,
    state: TrackingState,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(Color.White.copy(alpha = 0.08f))
            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(18.dp))
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment     = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(DashboardGreen.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Filled.Notifications,
                null,
                tint     = DashboardGreen,
                modifier = Modifier.size(18.dp)
            )
        }

        Column(
            modifier            = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                campaign.displayBank,
                fontSize   = 11.sp,
                fontWeight = FontWeight.Bold,
                color      = DashboardGreen
            )
            Text(
                campaign.title,
                fontSize   = 14.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary,
                lineHeight = 18.sp,
                maxLines   = 2,
                overflow   = TextOverflow.Ellipsis
            )
            val reminderText = formatReminderDate(state.reminderDateText)
            if (reminderText.isNotEmpty()) {
                Text(
                    "📅 $reminderText",
                    fontSize   = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary.copy(alpha = 0.74f)
                )
            }
        }

        Icon(
            Icons.Filled.ChevronRight,
            null,
            tint     = TextPrimary.copy(alpha = 0.46f),
            modifier = Modifier.padding(top = 10.dp)
        )
    }
}

// ── Takip edilen kampanya satırı ────────────────────────────────

@Composable
private fun EarningsCampaignRow(
    campaign: Campaign,
    state: TrackingState,
    onClick: () -> Unit
) {
    val didJoin = state.isTracking
    val spent   = state.spentText.toDoubleOrNull() ?: 0.0
    val earned  = state.earnedText.toDoubleOrNull() ?: 0.0
    val net     = earned - spent

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.08f))
            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(20.dp))
            .clickable { onClick() }
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            verticalAlignment     = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .clip(CircleShape)
                    .background(
                        if (didJoin) DashboardGreen
                        else Color.White.copy(alpha = 0.12f)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (didJoin) Icons.Filled.Check
                                  else Icons.Outlined.BookmarkBorder,
                    contentDescription = null,
                    tint     = if (didJoin) NearBlack else TextPrimary.copy(alpha = 0.74f),
                    modifier = Modifier.size(18.dp)
                )
            }

            Column(
                modifier            = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    campaign.displayBank,
                    fontSize   = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color      = DashboardGreen
                )
                Text(
                    campaign.title,
                    fontSize   = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    lineHeight = 19.sp,
                    maxLines   = 2,
                    overflow   = TextOverflow.Ellipsis
                )
                Text(
                    campaign.deadlineText,
                    fontSize   = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = TextPrimary.copy(alpha = 0.62f)
                )
                val reminderText = formatReminderDate(state.reminderDateText)
                if (state.reminderEnabled && reminderText.isNotEmpty()) {
                    Text(
                        "🔔 Puan son kullanım: $reminderText",
                        fontSize   = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color      = DashboardGreen
                    )
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            MiniMoneyPill(modifier = Modifier.weight(1f), title = "Harcama", value = spent.currencyText())
            MiniMoneyPill(modifier = Modifier.weight(1f), title = "Kazanç",  value = earned.currencyText())
            MiniMoneyPill(modifier = Modifier.weight(1f), title = "Net",     value = net.currencyText())
        }
    }
}

@Composable
private fun EmptyTrackedCard() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White.copy(alpha = 0.08f))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(
            Icons.AutoMirrored.Filled.TrendingUp,
            null,
            tint     = DashboardGreen,
            modifier = Modifier.size(26.dp)
        )
        Text("Henüz takip yok", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        Text(
            "Bir kampanya detayına girip katılım, harcama veya kazanç bilgisi eklediğinde burada görünecek.",
            fontSize   = 13.sp,
            color      = TextPrimary.copy(alpha = 0.68f),
            lineHeight = 18.sp
        )
    }
}

// ── Yardımcı composable'lar ─────────────────────────────────────

@Composable
internal fun DarkStatTile(
    modifier: Modifier = Modifier,
    title: String,
    value: String
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.08f))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            title,
            fontSize   = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color      = TextPrimary.copy(alpha = 0.62f)
        )
        Text(
            value,
            fontSize   = 15.sp,
            fontWeight = FontWeight.Bold,
            color      = TextPrimary,
            maxLines   = 1,
            overflow   = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun MiniMoneyPill(
    modifier: Modifier = Modifier,
    title: String,
    value: String
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White.copy(alpha = 0.08f))
            .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            title,
            fontSize   = 10.sp,
            fontWeight = FontWeight.SemiBold,
            color      = TextPrimary.copy(alpha = 0.56f)
        )
        Text(
            value,
            fontSize   = 12.sp,
            fontWeight = FontWeight.Bold,
            color      = TextPrimary,
            maxLines   = 1,
            overflow   = TextOverflow.Ellipsis
        )
    }
}

// ── Pure helpers ────────────────────────────────────────────────

internal fun Double.currencyText(): String {
    if (this == 0.0) return "0 TL"
    val rounded = String.format(Locale("tr", "TR"), "%,.0f", this)
    return "$rounded TL"
}

private fun rewardRateText(totalSpent: Double, totalEarned: Double): String {
    if (totalSpent <= 0.0) return "%0"
    val rate = (totalEarned / totalSpent) * 100.0
    val needsDecimal = rate < 10.0 && rate != kotlin.math.floor(rate)
    val pattern = if (needsDecimal) "%.1f" else "%.0f"
    return "%" + String.format(Locale("tr", "TR"), pattern, rate)
}

private fun formatReminderDate(iso: String): String {
    if (iso.isEmpty()) return ""
    return try {
        val date = LocalDate.parse(iso)
        val fmt  = DateTimeFormatter.ofPattern("d MMM yyyy", Locale("tr", "TR"))
        date.format(fmt)
    } catch (_: Exception) {
        iso
    }
}

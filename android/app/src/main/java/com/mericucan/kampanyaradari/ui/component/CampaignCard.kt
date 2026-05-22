package com.mericucan.kampanyaradari.ui.component

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Percent
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.ui.theme.*
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun CampaignCard(
    campaign: Campaign,
    isFavorite: Boolean,
    onFavoriteClick: () -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val shape  = RoundedCornerShape(20.dp)
    val accent = bankBrandColor(campaign.bank)
    val score  = campaign.opportunityScore ?: 50

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(
                Brush.linearGradient(
                    colors = listOf(PanelBlack, DeepBlue),
                    start  = Offset.Zero,
                    end    = Offset.Infinite
                )
            )
            .border(1.dp, BorderSubtle, shape)
            .clickable { onClick() }
            .height(IntrinsicSize.Min),
        verticalAlignment = Alignment.Top
    ) {
        // ── Sol banka rayı (accent gradient) ─────────────────
        BankRail(
            displayBank = campaign.displayBank,
            accent      = accent
        )

        // ── Sağ içerik ───────────────────────────────────────
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ── Üst kısım: badges + başlık + özet + tarih ─ // favori + skor
            Row(
                modifier          = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier            = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Badge'ler
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        PillBadge(
                            text       = leadingBadgeText(campaign),
                            foreground = accent,
                            background = accent.copy(alpha = 0.16f),
                            icon       = leadingBadgeIcon(campaign)
                        )
                        PillBadge(
                            text       = recommendationText(score),
                            foreground = DashboardGreen,
                            background = DashboardGreen.copy(alpha = 0.15f),
                            icon       = Icons.Filled.AutoAwesome
                        )
                    }

                    // Başlık
                    Text(
                        text       = campaign.title,
                        fontSize   = 16.sp,
                        fontWeight = FontWeight.Black,
                        color      = Color.White,
                        lineHeight = 20.sp,
                        maxLines   = 2,
                        overflow   = TextOverflow.Ellipsis
                    )

                    // Özet
                    Text(
                        text       = campaign.displaySummary,
                        fontSize   = 12.sp,
                        color      = Color.White.copy(alpha = 0.70f),
                        lineHeight = 16.sp,
                        maxLines   = 2,
                        overflow   = TextOverflow.Ellipsis
                    )

                    // Ödül değeri (varsa)
                    val rewardDisplay = campaign.rewardDisplayValue
                    if (rewardDisplay.isNotEmpty()) {
                        Text(
                            text       = rewardDisplay,
                            fontSize   = 14.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color      = GoldLight
                        )
                    }

                    // Tarih satırı: "Son tarih X" + deadline rozeti
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment     = Alignment.CenterVertically
                    ) {
                        InfoLabel(
                            icon = Icons.Filled.CalendarMonth,
                            text = dateRangeText(campaign)
                        )
                        val dColor = deadlineColor(campaign, accent)
                        PillBadge(
                            text       = campaign.deadlineText,
                            foreground = dColor,
                            background = dColor.copy(alpha = 0.18f),
                            icon       = Icons.Filled.Timer,
                            small      = true
                        )
                    }
                }

                Spacer(Modifier.width(8.dp))

                // Sağ üst: favori ikonu + skor göstergesi
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(
                        onClick  = onFavoriteClick,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            imageVector = if (isFavorite) Icons.Filled.Bookmark
                                          else Icons.Outlined.BookmarkBorder,
                            contentDescription = null,
                            tint     = if (isFavorite) accent else Color.White.copy(alpha = 0.76f),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    ScoreGauge(score = score, accent = accent)
                }
            }

            HorizontalDivider(color = BorderSubtle)

            // ── Alt satır: sosyal kanıt + Detaya Git ─────────
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.CenterVertically
            ) {
                InfoLabel(
                    icon = Icons.Filled.People,
                    text = socialProofText(score)
                )
                Row(
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        "Detaya Git",
                        fontSize   = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color      = DashboardGreen
                    )
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward,
                        null,
                        tint     = DashboardGreen,
                        modifier = Modifier.size(14.dp)
                    )
                }
            }
        }
    }
}

// ── Banka rayı ──────────────────────────────────────────────────

@Composable
private fun BankRail(displayBank: String, accent: Color) {
    Column(
        modifier = Modifier
            .width(80.dp)
            .fillMaxHeight()
            .background(
                Brush.linearGradient(
                    colors = listOf(accent.copy(alpha = 0.92f), accent.copy(alpha = 0.30f)),
                    start  = Offset.Zero,
                    end    = Offset.Infinite
                )
            )
            .padding(horizontal = 8.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text       = bankInitials(displayBank),
            fontSize   = 30.sp,
            fontWeight = FontWeight.Black,
            color      = Color.White,
            textAlign  = TextAlign.Center,
            maxLines   = 1
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text       = displayBank,
            fontSize   = 10.sp,
            fontWeight = FontWeight.Bold,
            color      = Color.White.copy(alpha = 0.92f),
            textAlign  = TextAlign.Center,
            maxLines   = 2,
            lineHeight = 12.sp,
            overflow   = TextOverflow.Ellipsis
        )
    }
}

// ── Skor göstergesi ─────────────────────────────────────────────

@Composable
private fun ScoreGauge(score: Int, accent: Color) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Box(
            modifier         = Modifier.size(width = 70.dp, height = 50.dp),
            contentAlignment = Alignment.Center
        ) {
            // Arc — alt smile şeklinde
            Canvas(modifier = Modifier.matchParentSize()) {
                val strokeW   = 6.dp.toPx()
                val arcInset  = strokeW / 2
                // Arc dikdörtgeni — iki katı yükseklikte (sadece alt yarısı görünsün)
                val arcSize  = androidx.compose.ui.geometry.Size(
                    width  = size.width - strokeW,
                    height = size.height * 1.6f
                )
                val topLeft = Offset(arcInset, -size.height * 0.30f)

                // Arka plan arc (soluk)
                drawArc(
                    color       = Color.White.copy(alpha = 0.14f),
                    startAngle  = 200f,
                    sweepAngle  = 140f,
                    useCenter   = false,
                    topLeft     = topLeft,
                    size        = arcSize,
                    style       = Stroke(width = strokeW, cap = StrokeCap.Round)
                )
                // Dolu arc (skor)
                val fillSweep = (score.coerceIn(0, 100) / 100f) * 140f
                drawArc(
                    color       = accent,
                    startAngle  = 200f,
                    sweepAngle  = fillSweep,
                    useCenter   = false,
                    topLeft     = topLeft,
                    size        = arcSize,
                    style       = Stroke(width = strokeW, cap = StrokeCap.Round)
                )
            }
            // Skor + "Skor"
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier            = Modifier.offset(y = (-2).dp)
            ) {
                Text(
                    "$score",
                    fontSize   = 18.sp,
                    fontWeight = FontWeight.Black,
                    color      = Color.White,
                    lineHeight = 18.sp
                )
                Text(
                    "Skor",
                    fontSize   = 9.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = Color.White.copy(alpha = 0.68f),
                    lineHeight = 10.sp
                )
            }
        }
        // Yıldızlar
        val filledStars = ((score / 100.0) * 5.0).toInt().coerceIn(1, 5)
        Row(horizontalArrangement = Arrangement.spacedBy(1.dp)) {
            repeat(5) { idx ->
                Icon(
                    imageVector = if (idx < filledStars) Icons.Filled.Star
                                  else Icons.Outlined.StarBorder,
                    contentDescription = null,
                    tint     = accent,
                    modifier = Modifier.size(10.dp)
                )
            }
        }
    }
}

// ── Yardımcı composable'lar ─────────────────────────────────────

@Composable
private fun PillBadge(
    text: String,
    foreground: Color,
    background: Color,
    icon: ImageVector? = null,
    small: Boolean = false
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(background)
            .padding(
                horizontal = if (small) 8.dp else 9.dp,
                vertical   = if (small) 3.dp else 4.dp
            ),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        if (icon != null) {
            Icon(icon, null, tint = foreground, modifier = Modifier.size(if (small) 10.dp else 11.dp))
        }
        Text(
            text,
            fontSize   = if (small) 10.sp else 11.sp,
            fontWeight = FontWeight.Bold,
            color      = foreground,
            maxLines   = 1
        )
    }
}

@Composable
private fun InfoLabel(icon: ImageVector, text: String) {
    Row(
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, null, tint = Color.White.copy(alpha = 0.74f), modifier = Modifier.size(12.dp))
        Text(
            text,
            fontSize   = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color      = Color.White.copy(alpha = 0.74f),
            maxLines   = 1,
            overflow   = TextOverflow.Ellipsis
        )
    }
}

// ── Pure fonksiyonlar (iOS karşılıkları) ────────────────────────

private fun leadingBadgeText(campaign: Campaign): String {
    val rt = campaign.rewardType
    if (!rt.isNullOrEmpty()) return rt.uppercase(Locale("tr", "TR"))
    return (campaign.category ?: "FIRSAT").uppercase(Locale("tr", "TR"))
}

private fun leadingBadgeIcon(campaign: Campaign): ImageVector {
    val text = leadingBadgeText(campaign).lowercase(Locale("tr", "TR"))
        .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
        .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
    return when {
        text.contains("taksit")                          -> Icons.Filled.CreditCard
        text.contains("puan") || text.contains("bonus") -> Icons.Filled.MonetizationOn
        text.contains("indirim")                         -> Icons.Filled.Percent
        else                                             -> Icons.Filled.LocalFireDepartment
    }
}

private fun recommendationText(score: Int): String = when {
    score >= 85 -> "Sizin için avantajlı"
    score >= 70 -> "AI Öneriyor"
    else        -> "Popüler"
}

private fun socialProofText(score: Int): String {
    val savedCount = maxOf(1_250, score * 143)
    val formatted = String.format(Locale("tr", "TR"), "%,d", savedCount)
    return "$formatted kişi kaydetti"
}

private fun dateRangeText(campaign: Campaign): String {
    val date = campaign.validToDate ?: return "Tarih kaynakta"
    val fmt  = DateTimeFormatter.ofPattern("d MMM yyyy", Locale("tr", "TR"))
    return "Son tarih ${date.format(fmt)}"
}

private fun deadlineColor(campaign: Campaign, accent: Color): Color {
    val text = campaign.deadlineText.lowercase(Locale("tr", "TR"))
        .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
        .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
    return if (text.contains("gecmis")) Color(0xFFFFA000) else accent
}

// bankBrandColor ve bankInitials → BankUtils.kt

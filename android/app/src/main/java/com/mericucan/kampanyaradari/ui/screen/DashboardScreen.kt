package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import com.mericucan.kampanyaradari.ui.component.icon
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.viewmodel.AuthViewModel
import com.mericucan.kampanyaradari.viewmodel.CampaignCategory
import com.mericucan.kampanyaradari.viewmodel.CampaignListViewModel

@Composable
fun DashboardScreen(
    viewModel: CampaignListViewModel,
    authViewModel: AuthViewModel,
    favoriteCount: Int,
    myCardCount: Int = 0,
    trackedJoinedCount: Int = 0,
    trackedTotalSpent: Double = 0.0,
    trackedTotalEarned: Double = 0.0,
    onOpenAllCampaigns: () -> Unit,
    onOpenFavorites: () -> Unit,
    onOpenMyCards: () -> Unit = {},
    onOpenMyCardsCampaigns: () -> Unit = {},
    onOpenEarnings: () -> Unit = {},
    onOpenCategory: (String) -> Unit,
    onOpenAccount: () -> Unit,
    onRefresh: () -> Unit
) {
    val campaigns    by viewModel.campaigns.collectAsStateWithLifecycle()
    val isLoading    by viewModel.isLoading.collectAsStateWithLifecycle()
    val lastSyncTime by viewModel.lastSyncTime.collectAsStateWithLifecycle()
    val isGuest      by authViewModel.isGuest.collectAsStateWithLifecycle()
    val displayName  by authViewModel.displayName.collectAsStateWithLifecycle()
    val plan         by authViewModel.plan.collectAsStateWithLifecycle()

    val categorySummaries = remember(campaigns) { viewModel.categorySummaries() }
    val bankCount = remember(campaigns) { campaigns.map { it.bank }.toSet().size }

    // Son güncelleme etiketi
    val syncLabel: String? = remember(lastSyncTime, isLoading) {
        if (isLoading) null
        else lastSyncTime?.let { ts ->
            val fmt = SimpleDateFormat("HH:mm", Locale("tr"))
            "${fmt.format(Date(ts))}'de güncellendi"
        }
    }

    // Sonsuz döndürme animasyonu (yalnızca isLoading=true iken uygulanır)
    val infiniteTransition = rememberInfiniteTransition(label = "sync")
    val syncAngle by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(800, easing = LinearEasing)),
        label = "syncAngle"
    )

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(NearBlack, Ink, NearBlack))),
        contentPadding = PaddingValues(horizontal = 22.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // ── Header ─────────────────────────────────────────────
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Column {
                        Text(
                            "Kampanya",
                            fontSize = 34.sp,
                            fontWeight = FontWeight.Black,
                            color = TextPrimary,
                            lineHeight = 38.sp
                        )
                        Text(
                            "Radarı",
                            fontSize = 34.sp,
                            fontWeight = FontWeight.Black,
                            color = DashboardGreen,
                            lineHeight = 38.sp
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            if (isGuest) "Misafir mod" else displayName,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = DashboardGreen
                        )
                        if (syncLabel != null) {
                            Text(
                                syncLabel,
                                fontSize = 11.sp,
                                color    = TextSecondary
                            )
                        }
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        DashCircleButton(Icons.Filled.AccountCircle, "Hesap", onClick = onOpenAccount)
                        SyncButton(
                            isLoading = isLoading,
                            syncAngle = syncAngle,
                            onClick   = onRefresh
                        )
                    }
                }

                Text(
                    "Bugünün kart fırsatlarını kategoriye, bankaya ve kazanca göre keşfet.",
                    fontSize = 15.sp,
                    color = TextPrimary.copy(alpha = 0.82f),
                    lineHeight = 22.sp
                )

                // Tüm Kampanyalar butonu
                Button(
                    onClick = onOpenAllCampaigns,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Icon(Icons.Filled.GridView, null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Tüm Kampanyalar",
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 16.sp
                    )
                }
            }
        }

        // ── Özet kartı ─────────────────────────────────────────
        item {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(24.dp))
                    .background(DashboardGreen.copy(alpha = 0.1f))
                    .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(24.dp))
                    .padding(18.dp)
            ) {
                if (isLoading && campaigns.isEmpty()) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        CircularProgressIndicator(color = DashboardGreen, modifier = Modifier.size(40.dp), strokeWidth = 3.dp)
                        Text("Kampanyalar yükleniyor...", color = TextSecondary, fontSize = 14.sp)
                    }
                } else {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Mini kategori özeti (halka yerine)
                        Column(
                            modifier = Modifier
                                .size(120.dp)
                                .clip(CircleShape)
                                .background(DashboardGreen.copy(alpha = 0.12f))
                                .border(2.dp, DashboardGreen.copy(alpha = 0.35f), CircleShape),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                "${campaigns.size}",
                                fontSize = 30.sp,
                                fontWeight = FontWeight.Black,
                                color = DashboardGreen
                            )
                            Text("kampanya", fontSize = 11.sp, color = TextSecondary)
                        }

                        Spacer(Modifier.width(16.dp))

                        Column(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Kampanya özeti", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                            DashStatRow("Toplam kampanya", "${campaigns.size}")
                            DashStatRow("Banka / kart",   "$bankCount")
                            DashStatRow("Favorilerim",    "$favoriteCount")
                            if (myCardCount > 0) {
                                DashStatRow("Kartlarım", "$myCardCount kart")
                            }
                            if (plan.isPremiumLike) {
                                DashStatRow("Plan", "⭐ Premium", valueColor = GoldLight)
                            }
                        }
                    }
                }
            }
        }

        // ── Favorilerim ─────────────────────────────────────────
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .border(1.dp, DashboardGreen.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
                    .clickable { onOpenFavorites() }
                    .padding(18.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(CircleShape)
                        .background(DashboardGreen.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Filled.Bookmark, null, tint = DashboardGreen, modifier = Modifier.size(24.dp))
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text("Favorilerim", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Text(
                        if (favoriteCount == 0) "Kaydettiğin kampanyalar burada görünecek"
                        else "$favoriteCount kayıtlı kampanya",
                        fontSize = 13.sp,
                        color = TextSecondary
                    )
                }

                Icon(Icons.Filled.ChevronRight, null, tint = DashboardGreen)
            }
        }

        // ── Kartlarım ───────────────────────────────────────────
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .border(1.dp, DashboardGreen.copy(alpha = 0.25f), RoundedCornerShape(20.dp))
                    .padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Üst satır: kart ikonu + başlık → sheet açar
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenMyCards() },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .clip(CircleShape)
                            .background(DashboardGreen.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.CreditCard, null, tint = DashboardGreen, modifier = Modifier.size(24.dp))
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Kartlarım", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                        Text(
                            if (myCardCount == 0) "Kartlarını ekle, kampanyaları filtrele"
                            else "$myCardCount kart kayıtlı",
                            fontSize = 13.sp,
                            color = TextSecondary
                        )
                    }
                    Icon(Icons.Filled.ChevronRight, null, tint = DashboardGreen)
                }

                // "Bana Uygun" butonu — yalnızca kart ekliyse göster
                if (myCardCount > 0) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(DashboardGreen.copy(alpha = 0.10f))
                            .border(1.dp, DashboardGreen.copy(alpha = 0.35f), RoundedCornerShape(14.dp))
                            .clickable { onOpenMyCardsCampaigns() }
                            .padding(horizontal = 16.dp, vertical = 13.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment     = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                Icons.Filled.CreditScore,
                                contentDescription = null,
                                tint     = DashboardGreen,
                                modifier = Modifier.size(20.dp)
                            )
                            Column {
                                Text(
                                    "Bana Uygun",
                                    fontSize   = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color      = TextPrimary
                                )
                                Text(
                                    "Kartlarıma özel kampanyaları gör",
                                    fontSize = 12.sp,
                                    color    = TextSecondary
                                )
                            }
                        }
                        Icon(
                            Icons.Filled.ChevronRight,
                            contentDescription = null,
                            tint     = DashboardGreen,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }

        // ── Kategori başlığı ─────────────────────────────────────
        item {
            Text("Kategoriler", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        }

        // ── Kategori grid (2 sütun) ─────────────────────────────
        item {
            if (categorySummaries.isEmpty() && isLoading) {
                // Yükleniyor placeholder
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.height(280.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    userScrollEnabled = false
                ) {
                    items(6) {
                        Box(
                            modifier = Modifier
                                .height(90.dp)
                                .clip(RoundedCornerShape(18.dp))
                                .background(PanelBlack)
                        )
                    }
                }
            } else {
                val rows = (categorySummaries.size + 1) / 2
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.height((rows * 112 + (rows - 1) * 12).dp.coerceAtLeast(280.dp)),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    userScrollEnabled = false
                ) {
                    items(categorySummaries) { (category, count) ->
                        CategoryTileCard(
                            category = category,
                            count    = count,
                            onClick  = { onOpenCategory(category.label) }
                        )
                    }
                }
            }
        }

        // ── Kazançlarım preview kartı ───────────────────────────
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.linearGradient(
                            listOf(PanelBlack, Color(0xFF082420))
                        )
                    )
                    .border(1.dp, DashboardGreen.copy(alpha = 0.28f), RoundedCornerShape(24.dp))
                    .clickable { onOpenEarnings() }
                    .padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        "Kazançlarım",
                        fontSize   = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color      = TextPrimary
                    )
                    Row(
                        verticalAlignment     = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.TrendingUp, null,
                            tint = DashboardGreen, modifier = Modifier.size(18.dp)
                        )
                        Icon(
                            Icons.Filled.ChevronRight, null,
                            tint = TextPrimary.copy(alpha = 0.62f), modifier = Modifier.size(18.dp)
                        )
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    DarkStatTile(
                        modifier = Modifier.weight(1f),
                        title = "Katılım", value = "$trackedJoinedCount"
                    )
                    DarkStatTile(
                        modifier = Modifier.weight(1f),
                        title = "Harcama", value = trackedTotalSpent.currencyText()
                    )
                    DarkStatTile(
                        modifier = Modifier.weight(1f),
                        title = "Kazanç", value = trackedTotalEarned.currencyText()
                    )
                }

                Text(
                    "Kampanya detaylarında katılım ve kazanç bilgilerini işaretleyebilirsin.",
                    fontSize   = 12.sp,
                    color      = TextPrimary.copy(alpha = 0.66f),
                    lineHeight = 17.sp
                )
            }
        }

        // Premium kayıt artık Hesap sayfasından açılıyor.

        item { Spacer(Modifier.height(16.dp)) }
    }
}

// ── Yardımcı bileşenler ───────────────────────────────────────

@Composable
private fun DashCircleButton(
    icon: ImageVector,
    contentDesc: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.08f))
            .border(1.dp, Color.White.copy(alpha = 0.1f), CircleShape)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDesc, tint = TextPrimary, modifier = Modifier.size(20.dp))
    }
}

@Composable
private fun SyncButton(
    isLoading: Boolean,
    syncAngle: Float,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(
                if (isLoading) DashboardGreen.copy(alpha = 0.15f)
                else Color.White.copy(alpha = 0.08f)
            )
            .border(
                1.dp,
                if (isLoading) DashboardGreen.copy(alpha = 0.40f)
                else Color.White.copy(alpha = 0.10f),
                CircleShape
            )
            .clickable(enabled = !isLoading) { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector        = Icons.Default.Refresh,
            contentDescription = "Senkronize et",
            tint               = if (isLoading) DashboardGreen else TextPrimary,
            modifier           = Modifier
                .size(20.dp)
                .rotate(if (isLoading) syncAngle else 0f)
        )
    }
}

@Composable
private fun DashStatRow(
    title: String,
    value: String,
    valueColor: Color = DashboardGreen
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(title, fontSize = 13.sp, color = TextSecondary)
        Text(value, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = valueColor)
    }
}

@Composable
private fun CategoryTileCard(
    category: CampaignCategory,
    count: Int,
    onClick: () -> Unit
) {
    val bg = when (category) {
        CampaignCategory.FUEL        -> Color(0xFF0D1E16)
        CampaignCategory.ELECTRONICS -> Color(0xFF0D1520)
        CampaignCategory.FASHION     -> Color(0xFF1A0D1A)
        CampaignCategory.MARKET      -> Color(0xFF0D1A10)
        CampaignCategory.RESTAURANT  -> Color(0xFF1A120D)
        CampaignCategory.TRAVEL      -> Color(0xFF0D161A)
        CampaignCategory.ONLINE      -> Color(0xFF111420)
    }
    val accent = when (category) {
        CampaignCategory.FUEL        -> Color(0xFF55E0C0)
        CampaignCategory.ELECTRONICS -> Color(0xFF178CFF)
        CampaignCategory.FASHION     -> Color(0xFFB64DFF)
        CampaignCategory.MARKET      -> Color(0xFF16C784)
        CampaignCategory.RESTAURANT  -> Color(0xFFF5B83D)
        CampaignCategory.TRAVEL      -> Color(0xFF19CDE8)
        CampaignCategory.ONLINE      -> Color(0xFF55E0C0)
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(112.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(bg)
            .border(1.dp, accent.copy(alpha = 0.3f), RoundedCornerShape(18.dp))
            .clickable { onClick() }
            .padding(14.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Kategori ikonu — kategori rengiyle vurgulanan yuvarlatılmış chip
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .clip(RoundedCornerShape(13.dp))
                    .background(accent.copy(alpha = 0.16f))
                    .border(1.dp, accent.copy(alpha = 0.28f), RoundedCornerShape(13.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    category.icon(),
                    contentDescription = category.label,
                    tint     = accent,
                    modifier = Modifier.size(26.dp)
                )
            }
            Text(
                "$count",
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = accent,
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(accent.copy(alpha = 0.15f))
                    .padding(horizontal = 7.dp, vertical = 3.dp)
            )
        }

        Text(
            category.label,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
    }
}

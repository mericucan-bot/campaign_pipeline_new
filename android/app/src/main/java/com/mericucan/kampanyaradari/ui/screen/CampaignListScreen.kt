package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.FormatListBulleted
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.domain.EntitlementRule
import com.mericucan.kampanyaradari.domain.EntitlementService
import com.mericucan.kampanyaradari.ui.component.CampaignCard
import com.mericucan.kampanyaradari.ui.component.EntitlementDialog
import com.mericucan.kampanyaradari.ui.component.icon
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.viewmodel.AuthViewModel
import com.mericucan.kampanyaradari.viewmodel.CampaignCategory
import com.mericucan.kampanyaradari.viewmodel.CampaignListViewModel
import com.mericucan.kampanyaradari.viewmodel.SortOption

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignListScreen(
    viewModel: CampaignListViewModel,
    authViewModel: AuthViewModel,
    favoriteIds: Set<String>,
    myCardBanks: Set<String>       = emptySet(),
    onFavoriteToggle: (String) -> Unit,
    onMyCardToggle: (String) -> Unit   = {},
    onOpenMyCards: () -> Unit          = {},
    onClearAllFavorites: () -> Unit    = {},
    onCampaignClick: (Campaign) -> Unit,
    onShowAuth: () -> Unit,
    onBack: (() -> Unit)?              = null
) {
    val campaigns          by viewModel.campaigns.collectAsStateWithLifecycle()
    val isLoading          by viewModel.isLoading.collectAsStateWithLifecycle()
    val error              by viewModel.error.collectAsStateWithLifecycle()
    val searchText         by viewModel.searchText.collectAsStateWithLifecycle()
    val selectedCategories by viewModel.selectedCategories.collectAsStateWithLifecycle()
    val selectedBanks      by viewModel.selectedBanks.collectAsStateWithLifecycle()
    val selectedRewardType by viewModel.selectedRewardType.collectAsStateWithLifecycle()
    val sortOption         by viewModel.sortOption.collectAsStateWithLifecycle()
    val showFavoritesOnly  by viewModel.showFavoritesOnly.collectAsStateWithLifecycle()
    val showMyCardsOnly    by viewModel.showMyCardsOnly.collectAsStateWithLifecycle()
    val isGuest            by authViewModel.isGuest.collectAsStateWithLifecycle()
    val plan               by authViewModel.plan.collectAsStateWithLifecycle()

    var entitlementDialogRule by remember { mutableStateOf<EntitlementRule?>(null) }

    // ── Misafir kapısı: giriş yapılmadıysa listeyi gösterme ───────
    if (isGuest) {
        GuestAuthGate(
            onShowAuth = onShowAuth,
            onBack     = onBack
        )
        return@CampaignListScreen
    }

    val filteredCampaigns = remember(
        campaigns, searchText, selectedCategories, selectedBanks, selectedRewardType,
        sortOption, showFavoritesOnly, showMyCardsOnly, favoriteIds, myCardBanks
    ) { viewModel.filteredCampaigns(favoriteIds, myCardBanks) }

    val allBanks  = remember(campaigns) { viewModel.allBanks() }
    // Chips satırı: Kartlarım varsa onları, yoksa tüm bankaları göster
    val chipBanks = if (myCardBanks.isNotEmpty()) myCardBanks.sorted() else allBanks

    var showSortSheet          by remember { mutableStateOf(false) }
    var showBankFilterSheet    by remember { mutableStateOf(false) }
    var showFiltrelerSheet     by remember { mutableStateOf(false) }
    var showClearFavDialog     by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = NearBlack,
        topBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(NearBlack)
                    .padding(horizontal = 20.dp)
            ) {
                Spacer(Modifier.height(8.dp))

                // ── Üst ikon satırı: geri ← → filtreler ─────────
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    // Sol: geri butonu
                    if (onBack != null) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(PanelBlack)
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
                    } else {
                        Spacer(Modifier.size(40.dp))
                    }

                    // Sağ: Filtreler (Tune) ikonu
                    val filtrelerActive =
                        selectedCategories.isNotEmpty() || selectedRewardType != null
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(
                                if (filtrelerActive) DashboardGreen.copy(alpha = 0.15f)
                                else PanelBlack
                            )
                            .border(
                                1.dp,
                                if (filtrelerActive) DashboardGreen.copy(alpha = 0.3f)
                                else BorderSubtle,
                                RoundedCornerShape(12.dp)
                            )
                            .clickable { showFiltrelerSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.Tune,
                            contentDescription = "Filtreler",
                            tint     = if (filtrelerActive) DashboardGreen else TextSecondary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }

                Spacer(Modifier.height(18.dp))

                // ── Başlık satırı + Tümünü kaldır ────────────────
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            if (showFavoritesOnly) "Favorilerim" else "Tüm Kampanyalar",
                            fontSize   = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color      = TextPrimary
                        )
                        if (!isLoading) {
                            Text(
                                "${filteredCampaigns.size} sonuç listeleniyor",
                                fontSize = 14.sp,
                                color    = TextSecondary
                            )
                        }
                    }
                    // "Tümünü kaldır" — sadece favorilerim modunda görünür
                    if (showFavoritesOnly) {
                        TextButton(
                            onClick        = { showClearFavDialog = true },
                            contentPadding = PaddingValues(horizontal = 6.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                Icons.Outlined.Delete,
                                null,
                                tint     = DashboardGreen,
                                modifier = Modifier.size(15.dp)
                            )
                            Spacer(Modifier.width(4.dp))
                            Text(
                                "Tümünü kaldır",
                                fontSize   = 13.sp,
                                color      = DashboardGreen,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }

                Spacer(Modifier.height(16.dp))

                // ── Arama çubuğu ───────────────────────────────────
                OutlinedTextField(
                    value         = searchText,
                    onValueChange = { viewModel.searchText.value = it },
                    placeholder   = {
                        Text("Market, ulaşım, taksit...", fontSize = 14.sp, color = TextSecondary)
                    },
                    leadingIcon   = {
                        Icon(Icons.Filled.Search, null, tint = TextSecondary, modifier = Modifier.size(20.dp))
                    },
                    trailingIcon  = {
                        if (searchText.isNotEmpty()) {
                            IconButton(onClick = { viewModel.searchText.value = "" }) {
                                Icon(Icons.Filled.Close, null, tint = TextSecondary)
                            }
                        }
                    },
                    singleLine  = true,
                    modifier    = Modifier.fillMaxWidth(),
                    shape       = RoundedCornerShape(14.dp),
                    colors      = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor      = DashboardGreen,
                        unfocusedBorderColor    = BorderSubtle,
                        focusedTextColor        = TextPrimary,
                        unfocusedTextColor      = TextPrimary,
                        cursorColor             = DashboardGreen,
                        focusedContainerColor   = PanelBlack,
                        unfocusedContainerColor = PanelBlack
                    )
                )

                Spacer(Modifier.height(10.dp))

                // ── Favorilerim tam genişlik kartı ─────────────────
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(
                            if (showFavoritesOnly) DashboardGreen else PanelBlack
                        )
                        .border(
                            1.dp,
                            if (showFavoritesOnly) DashboardGreen else BorderSubtle,
                            RoundedCornerShape(14.dp)
                        )
                        .clickable {
                            if (!isGuest) {
                                val turningOn = !showFavoritesOnly
                                viewModel.showFavoritesOnly.value = turningOn
                                if (turningOn) {
                                    viewModel.selectedBanks.value   = emptySet()
                                    viewModel.showMyCardsOnly.value = false
                                }
                            } else onShowAuth()
                        }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment     = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(
                            Icons.Filled.Bookmark,
                            null,
                            tint     = if (showFavoritesOnly) NearBlack else TextSecondary,
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            if (showFavoritesOnly) "Favoriler gösteriliyor" else "Favorilerim",
                            fontSize   = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            color      = if (showFavoritesOnly) NearBlack else TextPrimary
                        )
                    }
                    if (favoriteIds.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(999.dp))
                                .background(
                                    if (showFavoritesOnly) Color.White else PanelBlack
                                )
                                .border(
                                    1.dp,
                                    if (showFavoritesOnly) Color.White else BorderSubtle,
                                    RoundedCornerShape(999.dp)
                                )
                                .padding(horizontal = 10.dp, vertical = 4.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "${favoriteIds.size}",
                                fontSize   = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color      = if (showFavoritesOnly) NearBlack else TextSecondary
                            )
                        }
                    }
                }

                Spacer(Modifier.height(10.dp))

                // ── Banka chip satırı ──────────────────────────────
                // [filtre ikonu] [sıralama ikonu] [Tümü] [banka1] [banka2] ...
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    // Banka filtresi ikonu
                    val filterActive = selectedBanks.isNotEmpty() || showMyCardsOnly
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(
                                if (filterActive) DashboardGreen.copy(alpha = 0.15f) else PanelBlack
                            )
                            .border(
                                1.dp,
                                if (filterActive) DashboardGreen.copy(alpha = 0.3f) else BorderSubtle,
                                RoundedCornerShape(10.dp)
                            )
                            .clickable { showBankFilterSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.FilterList,
                            null,
                            tint     = if (filterActive) DashboardGreen else TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    // Sıralama ikonu
                    val sortActive = sortOption != SortOption.EXPIRING_SOON
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(
                                if (sortActive) DashboardGreen.copy(alpha = 0.15f) else PanelBlack
                            )
                            .border(
                                1.dp,
                                if (sortActive) DashboardGreen.copy(alpha = 0.3f) else BorderSubtle,
                                RoundedCornerShape(10.dp)
                            )
                            .clickable { showSortSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.SwapVert,
                            null,
                            tint     = if (sortActive) DashboardGreen else TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    // Tümü chip
                    val allSelected = selectedBanks.isEmpty() && !showMyCardsOnly && !showFavoritesOnly
                    FilterChip(
                        selected = allSelected,
                        onClick  = {
                            viewModel.selectedBanks.value     = emptySet()
                            viewModel.showMyCardsOnly.value   = false
                            viewModel.showFavoritesOnly.value = false
                        },
                        label  = { Text("Tümü", fontSize = 13.sp) },
                        colors = filterChipColors()
                    )

                    // Banka chip'leri
                    chipBanks.forEach { bank ->
                        val isSelected = selectedBanks.contains(bank)
                        FilterChip(
                            selected = isSelected,
                            onClick  = {
                                viewModel.showMyCardsOnly.value   = false
                                viewModel.showFavoritesOnly.value = false
                                val cur = viewModel.selectedBanks.value
                                viewModel.selectedBanks.value =
                                    if (isSelected) cur - bank else cur + bank
                            },
                            label  = { Text(viewModel.bankLabel(bank), fontSize = 13.sp) },
                            colors = filterChipColors()
                        )
                    }
                }

                Spacer(Modifier.height(8.dp))

                // ── Sonuç sayısı + Temizle ─────────────────────────
                Row(
                    modifier              = Modifier.fillMaxWidth().padding(bottom = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment     = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.FormatListBulleted,
                            null,
                            tint     = TextSecondary,
                            modifier = Modifier.size(14.dp)
                        )
                        Text("${filteredCampaigns.size} sonuç", fontSize = 13.sp, color = TextSecondary)
                    }
                    if (viewModel.hasActiveFilters() || searchText.isNotEmpty()) {
                        TextButton(
                            onClick = {
                                viewModel.resetFilters()
                                viewModel.searchText.value = ""
                            },
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                        ) {
                            Text(
                                "Temizle",
                                fontSize   = 13.sp,
                                color      = DashboardGreen,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
    ) { padding ->
        when {
            isLoading -> LoadingView(Modifier.padding(padding))
            error != null -> ErrorView(
                message  = error!!,
                onRetry  = { viewModel.load() },
                modifier = Modifier.padding(padding)
            )
            filteredCampaigns.isEmpty() -> EmptyView(Modifier.padding(padding))
            else -> LazyColumn(
                modifier        = Modifier.padding(padding),
                contentPadding  = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(filteredCampaigns, key = { it.id }) { campaign ->
                    CampaignCard(
                        campaign        = campaign,
                        isFavorite      = favoriteIds.contains(campaign.id),
                        onFavoriteClick = {
                            val rule = EntitlementService.canAddFavorite(plan, favoriteIds, campaign.id, isGuest)
                            if (rule.allowed) onFavoriteToggle(campaign.id)
                            else entitlementDialogRule = rule
                        },
                        onClick         = { onCampaignClick(campaign) }
                    )
                }
                item { Spacer(Modifier.height(16.dp)) }
            }
        }
    }

    // ── Sıralama bottom sheet ──────────────────────────────────────
    if (showSortSheet) {
        ModalBottomSheet(
            onDismissRequest = { showSortSheet = false },
            containerColor   = Ink
        ) {
            SiralamaSheet(
                currentSort = sortOption,
                onSelect    = { viewModel.sortOption.value = it; showSortSheet = false },
                onReset     = {
                    viewModel.sortOption.value = SortOption.EXPIRING_SOON
                    showSortSheet = false
                },
                onDismiss   = { showSortSheet = false }
            )
        }
    }

    // ── Banka Filtresi bottom sheet ────────────────────────────────
    if (showBankFilterSheet) {
        ModalBottomSheet(
            onDismissRequest = { showBankFilterSheet = false },
            containerColor   = Ink
        ) {
            BankaFiltresiSheet(
                allBanks      = allBanks,
                selectedBanks = selectedBanks,
                bankLabel     = { viewModel.bankLabel(it) },
                onBankToggle  = { bank ->
                    viewModel.showMyCardsOnly.value = false
                    val cur = viewModel.selectedBanks.value
                    viewModel.selectedBanks.value =
                        if (cur.contains(bank)) cur - bank else cur + bank
                },
                onSelectAll   = {
                    viewModel.selectedBanks.value   = emptySet()
                    viewModel.showMyCardsOnly.value = false
                },
                onDismiss     = { showBankFilterSheet = false }
            )
        }
    }

    // ── Filtreler bottom sheet ─────────────────────────────────────
    if (showFiltrelerSheet) {
        ModalBottomSheet(
            onDismissRequest = { showFiltrelerSheet = false },
            containerColor   = Ink
        ) {
            FiltrelerSheet(
                selectedCategories   = selectedCategories,
                selectedRewardType   = selectedRewardType,
                showFavoritesOnly    = showFavoritesOnly,
                showMyCardsOnly      = showMyCardsOnly,
                favoriteCount        = favoriteIds.size,
                myCardCount          = myCardBanks.size,
                onCategorySelect     = { cat ->
                    viewModel.selectedCategories.value =
                        if (cat == null) emptySet() else setOf(cat)
                },
                onRewardTypeSelect   = { viewModel.selectedRewardType.value = it },
                onShowFavoritesToggle = {
                    val next = !viewModel.showFavoritesOnly.value
                    viewModel.showFavoritesOnly.value = next
                    if (next) viewModel.showMyCardsOnly.value = false
                },
                onShowMyCardsToggle  = {
                    val next = !viewModel.showMyCardsOnly.value
                    viewModel.showMyCardsOnly.value = next
                    if (next) viewModel.showFavoritesOnly.value = false
                },
                onClearAll           = {
                    viewModel.selectedCategories.value = emptySet()
                    viewModel.selectedRewardType.value = null
                    showFiltrelerSheet = false
                },
                onDismiss            = { showFiltrelerSheet = false }
            )
        }
    }

    // ── Entitlement engel diyaloğu ─────────────────────────────────
    entitlementDialogRule?.let { rule ->
        EntitlementDialog(
            title          = rule.title,
            message        = rule.message,
            isAuthRequired = !rule.allowed && rule.title == "Giriş gerekli",
            onDismiss      = { entitlementDialogRule = null },
            onShowAuth     = { entitlementDialogRule = null; onShowAuth() }
        )
    }

    // ── Tüm favorileri sil onay diyaloğu ──────────────────────────
    if (showClearFavDialog) {
        Dialog(onDismissRequest = { showClearFavDialog = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(PanelBlack)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Yeşil daire + çöp ikonu
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(DashboardGreen.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Outlined.Delete,
                        null,
                        tint     = DashboardGreen,
                        modifier = Modifier.size(32.dp)
                    )
                }

                Text(
                    "Favorileri Temizle",
                    fontSize   = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary
                )

                Text(
                    "${favoriteIds.size} kampanya favorilerden kaldırılacak.",
                    fontSize   = 14.sp,
                    color      = TextSecondary,
                    textAlign  = TextAlign.Center
                )

                // Tümünü Kaldır
                Button(
                    onClick = {
                        onClearAllFavorites()
                        viewModel.showFavoritesOnly.value = false
                        showClearFavDialog = false
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape  = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Text("Tümünü Kaldır", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                }

                // Vazgeç
                Button(
                    onClick = { showClearFavDialog = false },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape  = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(
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

// ── Filtreler sheet ─────────────────────────────────────────────

@Composable
private fun FiltrelerSheet(
    selectedCategories: Set<String>,
    selectedRewardType: String?,
    showFavoritesOnly: Boolean,
    showMyCardsOnly: Boolean,
    favoriteCount: Int,
    myCardCount: Int,
    onCategorySelect: (String?) -> Unit,
    onRewardTypeSelect: (String?) -> Unit,
    onShowFavoritesToggle: () -> Unit,
    onShowMyCardsToggle: () -> Unit,
    onClearAll: () -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 4.dp, bottom = 32.dp)
            .navigationBarsPadding()
    ) {
        // ── Başlık ─────────────────────────────────────────────────
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.CenterVertically
        ) {
            Column {
                Text("Filtreler", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text("Sonuçları hızlıca daralt", fontSize = 13.sp, color = TextSecondary)
            }
            IconButton(onClick = onDismiss) {
                Icon(Icons.Filled.Close, null, tint = TextSecondary)
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Kategori ───────────────────────────────────────────────
        FiltrelerSectionLabel(icon = Icons.Filled.Category, title = "Kategori")
        Spacer(Modifier.height(10.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(NearBlack)
                .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
        ) {
            // Tümü
            FiltrelerSelectRow(
                label       = "Tümü",
                isSelected  = selectedCategories.isEmpty(),
                onClick     = { onCategorySelect(null) },
                showDivider = true
            )
            // Kategoriler
            CampaignCategory.entries.forEachIndexed { idx, cat ->
                val isSelected = selectedCategories.contains(cat.label)
                FiltrelerSelectRow(
                    label       = cat.label,
                    icon        = cat.icon(),
                    isSelected  = isSelected,
                    onClick     = { onCategorySelect(if (isSelected) null else cat.label) },
                    showDivider = idx < CampaignCategory.values().lastIndex
                )
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Kazanım ────────────────────────────────────────────────
        FiltrelerSectionLabel(icon = Icons.Filled.Stars, title = "Kazanım")
        Spacer(Modifier.height(10.dp))

        val rewardTypes = listOf("Fırsat", "İndirim", "Puan", "Taksit")
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(NearBlack)
                .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
        ) {
            // Tümü
            FiltrelerSelectRow(
                label       = "Tümü",
                isSelected  = selectedRewardType == null,
                onClick     = { onRewardTypeSelect(null) },
                showDivider = true
            )
            rewardTypes.forEachIndexed { idx, rw ->
                val isSelected = selectedRewardType == rw
                FiltrelerSelectRow(
                    label       = rw,
                    isSelected  = isSelected,
                    onClick     = { onRewardTypeSelect(if (isSelected) null else rw) },
                    showDivider = idx < rewardTypes.lastIndex
                )
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Görünüm ────────────────────────────────────────────────
        FiltrelerSectionLabel(icon = Icons.Filled.Visibility, title = "Görünüm")
        Spacer(Modifier.height(10.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(NearBlack)
                .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
        ) {
            // Sadece favoriler
            FiltrelerToggleRow(
                icon      = Icons.Filled.Bookmark,
                label     = "Sadece favoriler",
                info      = if (favoriteCount > 0) "$favoriteCount favoride" else "Favori yok",
                checked   = showFavoritesOnly,
                onToggle  = onShowFavoritesToggle,
                showDivider = true
            )
            // Benim kartlarım
            FiltrelerToggleRow(
                icon      = Icons.Filled.CreditCard,
                label     = "Benim kartlarım",
                info      = if (myCardCount > 0) "$myCardCount kart eklendi" else "Kart eklenmedi",
                checked   = showMyCardsOnly,
                onToggle  = onShowMyCardsToggle,
                showDivider = false
            )
        }

        Spacer(Modifier.height(24.dp))

        // ── Filtreleri Temizle ─────────────────────────────────────
        Button(
            onClick  = onClearAll,
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape    = RoundedCornerShape(14.dp),
            colors   = ButtonDefaults.buttonColors(
                containerColor = DashboardGreen,
                contentColor   = NearBlack
            )
        ) {
            Text("Filtreleri Temizle", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
        }
    }
}

// ── Sıralama sheet ─────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SiralamaSheet(
    currentSort: SortOption,
    onSelect: (SortOption) -> Unit,
    onReset: () -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 4.dp, bottom = 32.dp)
            .navigationBarsPadding()
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.CenterVertically
        ) {
            Column {
                Text("Sıralama", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text("Liste akışını düzenle", fontSize = 13.sp, color = TextSecondary)
            }
            IconButton(onClick = onDismiss) {
                Icon(Icons.Filled.Close, null, tint = TextSecondary)
            }
        }

        Spacer(Modifier.height(16.dp))

        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(Icons.Filled.SwapVert, null, tint = TextSecondary, modifier = Modifier.size(16.dp))
            Text("Sıralama türü", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TextSecondary)
        }

        Spacer(Modifier.height(10.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(PanelBlack)
                .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
        ) {
            SortOption.entries.forEachIndexed { idx, option ->
                if (idx > 0) HorizontalDivider(color = BorderSubtle)
                val isSelected = currentSort == option
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            if (isSelected) DashboardGreen.copy(alpha = 0.1f) else PanelBlack
                        )
                        .clickable { onSelect(option) }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment     = Alignment.CenterVertically
                ) {
                    Text(
                        option.label,
                        fontSize   = 15.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                        color      = if (isSelected) DashboardGreen else TextPrimary
                    )
                    if (isSelected) {
                        Icon(Icons.Filled.Check, null, tint = DashboardGreen, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        Button(
            onClick  = onReset,
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape    = RoundedCornerShape(14.dp),
            colors   = ButtonDefaults.buttonColors(
                containerColor = DashboardGreen,
                contentColor   = NearBlack
            )
        ) {
            Text("Varsayılana Dön", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
        }
    }
}

// ── Banka Filtresi sheet ────────────────────────────────────────

@Composable
private fun BankaFiltresiSheet(
    allBanks: List<String>,
    selectedBanks: Set<String>,
    bankLabel: (String) -> String,
    onBankToggle: (String) -> Unit,
    onSelectAll: () -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 4.dp, bottom = 32.dp)
            .navigationBarsPadding()
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.CenterVertically
        ) {
            Column {
                Text("Banka Filtresi", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text("Bir veya birden fazla banka seç", fontSize = 13.sp, color = TextSecondary)
            }
            IconButton(onClick = onDismiss) {
                Icon(Icons.Filled.Close, null, tint = TextSecondary)
            }
        }

        Spacer(Modifier.height(16.dp))

        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(Icons.Filled.CreditCard, null, tint = TextSecondary, modifier = Modifier.size(16.dp))
            Text("Bankalar", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TextSecondary)
        }

        Spacer(Modifier.height(10.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 460.dp)
                .verticalScroll(rememberScrollState())
                .clip(RoundedCornerShape(14.dp))
                .background(PanelBlack)
                .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
        ) {
            BankFilterRow(
                label       = "Tümü",
                isSelected  = selectedBanks.isEmpty(),
                onClick     = onSelectAll,
                showDivider = allBanks.isNotEmpty()
            )
            allBanks.forEachIndexed { idx, bank ->
                BankFilterRow(
                    label       = bankLabel(bank),
                    isSelected  = selectedBanks.contains(bank),
                    onClick     = { onBankToggle(bank) },
                    showDivider = idx < allBanks.lastIndex
                )
            }
        }
    }
}

// ── Küçük yardımcı composable'lar ───────────────────────────────

@Composable
private fun FiltrelerSectionLabel(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String
) {
    Row(
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(icon, null, tint = TextSecondary, modifier = Modifier.size(16.dp))
        Text(title, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TextSecondary)
    }
}

@Composable
private fun FiltrelerSelectRow(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    showDivider: Boolean,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (isSelected) DashboardGreen.copy(alpha = 0.12f) else Color.Transparent)
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier              = Modifier.weight(1f)
        ) {
            if (icon != null) {
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(
                            if (isSelected) DashboardGreen.copy(alpha = 0.18f)
                            else PanelBlack
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        icon,
                        null,
                        tint     = if (isSelected) DashboardGreen else TextPrimary.copy(alpha = 0.82f),
                        modifier = Modifier.size(17.dp)
                    )
                }
            }
            Text(
                label,
                fontSize   = 15.sp,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                color      = if (isSelected) DashboardGreen else TextPrimary
            )
        }
        if (isSelected) {
            Icon(Icons.Filled.Check, null, tint = DashboardGreen, modifier = Modifier.size(18.dp))
        }
    }
    if (showDivider) HorizontalDivider(color = BorderSubtle)
}

@Composable
private fun FiltrelerToggleRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    info: String,
    checked: Boolean,
    onToggle: () -> Unit,
    showDivider: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onToggle() }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            modifier              = Modifier.weight(1f)
        ) {
            Icon(
                icon, null,
                tint     = if (checked) DashboardGreen else TextSecondary,
                modifier = Modifier.size(18.dp)
            )
            Column {
                Text(
                    label,
                    fontSize   = 15.sp,
                    fontWeight = if (checked) FontWeight.SemiBold else FontWeight.Normal,
                    color      = if (checked) DashboardGreen else TextPrimary
                )
                Text(info, fontSize = 12.sp, color = TextSecondary)
            }
        }
        Switch(
            checked         = checked,
            onCheckedChange = { onToggle() },
            colors          = SwitchDefaults.colors(
                checkedThumbColor       = NearBlack,
                checkedTrackColor       = DashboardGreen,
                uncheckedThumbColor     = TextSecondary,
                uncheckedTrackColor     = PanelBlack,
                uncheckedBorderColor    = BorderSubtle
            )
        )
    }
    if (showDivider) HorizontalDivider(color = BorderSubtle)
}

@Composable
private fun BankFilterRow(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    showDivider: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (isSelected) DashboardGreen.copy(alpha = 0.12f) else PanelBlack)
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Text(
            label,
            fontSize   = 15.sp,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            color      = if (isSelected) DashboardGreen else TextPrimary
        )
        if (isSelected) {
            Icon(Icons.Filled.Check, null, tint = DashboardGreen, modifier = Modifier.size(18.dp))
        }
    }
    if (showDivider) HorizontalDivider(color = BorderSubtle)
}

// ── Yardımcı view'lar ───────────────────────────────────────────

@Composable
private fun LoadingView(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CircularProgressIndicator(color = DashboardGreen)
            Text("Kampanyalar yükleniyor...", color = TextSecondary, fontSize = 14.sp)
        }
    }
}

@Composable
private fun ErrorView(message: String, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier            = Modifier.padding(32.dp)
        ) {
            Text("⚠️", fontSize = 40.sp)
            Text(message, color = TextSecondary, fontSize = 14.sp)
            Button(
                onClick = onRetry,
                colors  = ButtonDefaults.buttonColors(
                    containerColor = DashboardGreen,
                    contentColor   = NearBlack
                )
            ) { Text("Tekrar dene") }
        }
    }
}

@Composable
private fun EmptyView(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("🔍", fontSize = 48.sp)
            Text("Sonuç bulunamadı", color = TextPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Text("Filtreni veya arama terimini değiştir", color = TextSecondary, fontSize = 13.sp)
        }
    }
}

// ── Misafir giriş kapısı ────────────────────────────────────────

@Composable
private fun GuestAuthGate(
    onShowAuth: () -> Unit,
    onBack: (() -> Unit)?
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(NearBlack)
    ) {
        // Geri butonu
        if (onBack != null) {
            Box(
                modifier = Modifier
                    .statusBarsPadding()
                    .padding(top = 16.dp, start = 20.dp)
                    .align(Alignment.TopStart)
                    .size(40.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(PanelBlack)
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

        // Orta içerik
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .padding(horizontal = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // İkon
            Box(
                modifier = Modifier
                    .size(88.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(DashboardGreen.copy(alpha = 0.12f))
                    .border(1.dp, DashboardGreen.copy(alpha = 0.25f), RoundedCornerShape(999.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Filled.Lock,
                    contentDescription = null,
                    tint     = DashboardGreen,
                    modifier = Modifier.size(38.dp)
                )
            }

            // Başlık
            Text(
                "Giriş Gerekli",
                fontSize   = 24.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary,
                textAlign  = TextAlign.Center
            )

            // Açıklama
            Text(
                "Kampanyaları görüntüleyebilmek için hesap oluşturman veya giriş yapman gerekiyor.",
                fontSize   = 14.sp,
                color      = TextSecondary,
                textAlign  = TextAlign.Center,
                lineHeight = 21.sp
            )

            Spacer(Modifier.height(4.dp))

            // Giriş butonu
            Button(
                onClick  = onShowAuth,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape  = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = DashboardGreen,
                    contentColor   = NearBlack
                )
            ) {
                Icon(
                    Icons.Filled.AccountCircle,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    "Giriş Yap / Hesap Oluştur",
                    fontWeight = FontWeight.ExtraBold,
                    fontSize   = 15.sp
                )
            }
        }
    }
}

@Composable
private fun filterChipColors() = FilterChipDefaults.filterChipColors(
    selectedContainerColor   = DashboardGreen.copy(alpha = 0.15f),
    selectedLabelColor       = DashboardGreen,
    selectedLeadingIconColor = DashboardGreen,
    containerColor           = PanelBlack,
    labelColor               = TextSecondary,
    iconColor                = TextSecondary
)

package com.mericucan.kampanyaradari

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.*
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.ui.screen.*
import com.mericucan.kampanyaradari.ui.theme.Ink
import com.mericucan.kampanyaradari.ui.theme.KampanyaRadariTheme
import com.mericucan.kampanyaradari.viewmodel.AuthViewModel
import com.mericucan.kampanyaradari.viewmodel.CampaignListViewModel
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val app = application as KampanyaRadariApp

        setContent {
            KampanyaRadariTheme {
                KampanyaRadariApp(app = app)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun KampanyaRadariApp(app: KampanyaRadariApp) {
    val navController  = rememberNavController()
    val authViewModel: AuthViewModel         = viewModel()
    val listViewModel: CampaignListViewModel = viewModel()
    val scope = rememberCoroutineScope()

    val onboardingSeen  by app.prefsStore.onboardingSeen.collectAsStateWithLifecycle(false)
    val favoriteIds     by app.favoritesStore.ids.collectAsStateWithLifecycle(emptySet())
    val myCardBanks     by app.myCardsStore.banks.collectAsStateWithLifecycle(emptySet())
    val trackingStates  by app.trackingStore.allStates.collectAsStateWithLifecycle(emptyMap())
    val isGuest         by authViewModel.isGuest.collectAsStateWithLifecycle()
    val plan            by authViewModel.plan.collectAsStateWithLifecycle()

    val campaigns       by listViewModel.campaigns.collectAsStateWithLifecycle()

    // Kazançlarım toplamları (takipte olan kampanyalar üzerinden)
    val trackedCount   = trackingStates.values.count { it.isTracking }
    val trackedSpent   = trackingStates.values
        .filter { it.isTracking }
        .sumOf { it.spentText.toDoubleOrNull() ?: 0.0 }
    val trackedEarned  = trackingStates.values
        .filter { it.isTracking }
        .sumOf { it.earnedText.toDoubleOrNull() ?: 0.0 }
    val activeReminderCount = trackingStates.values.count { it.reminderEnabled }

    // Sheet states
    var showAuthSheet    by remember { mutableStateOf(false) }
    var showMyCardsSheet by remember { mutableStateOf(false) }
    var showPremiumSheet by remember { mutableStateOf(false) }
    val authSheetState    = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val cardsSheetState   = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val premiumSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var selectedCampaign by remember { mutableStateOf<Campaign?>(null) }

    val startDest = if (onboardingSeen) "dashboard" else "onboarding"

    NavHost(
        navController    = navController,
        startDestination = startDest,
        modifier         = Modifier.fillMaxSize()
    ) {

        composable("onboarding") {
            OnboardingScreen(
                onFinish = {
                    scope.launch { app.prefsStore.setOnboardingSeen(true) }
                    navController.navigate("dashboard") {
                        popUpTo("onboarding") { inclusive = true }
                    }
                }
            )
        }

        composable("dashboard") {
            DashboardScreen(
                viewModel            = listViewModel,
                authViewModel        = authViewModel,
                favoriteCount        = favoriteIds.size,
                myCardCount          = myCardBanks.size,
                trackedJoinedCount   = trackedCount,
                trackedTotalSpent    = trackedSpent,
                trackedTotalEarned   = trackedEarned,
                onOpenAllCampaigns   = {
                    listViewModel.resetFilters()
                    listViewModel.searchText.value = ""
                    navController.navigate("list")
                },
                onOpenFavorites      = {
                    listViewModel.resetFilters()
                    listViewModel.showFavoritesOnly.value = true
                    navController.navigate("list")
                },
                onOpenMyCards        = { showMyCardsSheet = true },
                onOpenMyCardsCampaigns = {
                    listViewModel.resetFilters()
                    listViewModel.showMyCardsOnly.value = true
                    navController.navigate("list")
                },
                onOpenEarnings       = { navController.navigate("earnings") },
                onOpenCategory       = { category ->
                    listViewModel.showCampaigns(category)
                    navController.navigate("list")
                },
                onOpenAccount        = { navController.navigate("account") },
                onRefresh            = { listViewModel.load() }
            )
        }

        composable("earnings") {
            EarningsScreen(
                campaigns          = campaigns,
                trackingStates     = trackingStates,
                onBack             = { navController.popBackStack() },
                onCampaignClick    = { campaign ->
                    selectedCampaign = campaign
                    navController.navigate("detail")
                },
                onClearAllTracking = { scope.launch { app.trackingStore.removeAll() } }
            )
        }

        composable("account") {
            AccountScreen(
                authViewModel       = authViewModel,
                favoriteCount       = favoriteIds.size,
                myCardCount         = myCardBanks.size,
                activeReminderCount = activeReminderCount,
                onBack              = { navController.popBackStack() },
                onShowAuth          = { showAuthSheet = true },
                onShowPaywall       = { showPremiumSheet = true }
            )
        }

        composable("list") {
            CampaignListScreen(
                viewModel        = listViewModel,
                authViewModel    = authViewModel,
                favoriteIds      = favoriteIds,
                myCardBanks      = myCardBanks,
                onFavoriteToggle    = { id -> scope.launch { app.favoritesStore.toggle(id) } },
                onMyCardToggle      = { bank -> scope.launch { app.myCardsStore.toggle(bank) } },
                onOpenMyCards       = { showMyCardsSheet = true },
                onClearAllFavorites = { scope.launch { app.favoritesStore.removeAll() } },
                onCampaignClick     = { campaign ->
                    selectedCampaign = campaign
                    navController.navigate("detail")
                },
                onShowAuth       = { showAuthSheet = true },
                onBack           = { navController.popBackStack() }
            )
        }

        composable("detail") {
            val campaign = selectedCampaign ?: return@composable
            CampaignDetailScreen(
                campaign            = campaign,
                trackingStore       = app.trackingStore,
                isFavorite          = favoriteIds.contains(campaign.id),
                favoriteCount       = favoriteIds.size,
                plan                = plan,
                isGuest             = isGuest,
                activeReminderCount = activeReminderCount,
                onFavoriteClick     = { scope.launch { app.favoritesStore.toggle(campaign.id) } },
                onShowAuth          = { showAuthSheet = true },
                onBack              = { navController.popBackStack() }
            )
        }
    }

    // ── Auth Bottom Sheet ────────────────────────────────────────
    if (showAuthSheet) {
        ModalBottomSheet(
            onDismissRequest = { showAuthSheet = false },
            sheetState       = authSheetState,
            containerColor   = androidx.compose.ui.graphics.Color.Transparent,
            modifier         = Modifier.imePadding()
        ) {
            AuthScreen(
                authViewModel = authViewModel,
                onDismiss     = {
                    scope.launch { authSheetState.hide() }
                        .invokeOnCompletion { showAuthSheet = false }
                }
            )
        }
    }

    // ── Kartlarım Bottom Sheet ───────────────────────────────────
    if (showMyCardsSheet) {
        ModalBottomSheet(
            onDismissRequest = { showMyCardsSheet = false },
            sheetState       = cardsSheetState,
            containerColor   = androidx.compose.ui.graphics.Color.Transparent
        ) {
            MyCardsSheet(
                allBanks        = listViewModel.allBanks(),
                bankLabel       = { listViewModel.bankLabel(it) },
                myCardBanks     = myCardBanks,
                onMyCardToggle  = { bank -> scope.launch { app.myCardsStore.toggle(bank) } },
                onShowCampaigns = {
                    listViewModel.resetFilters()
                    listViewModel.showMyCardsOnly.value = true
                    // Liste sayfasına git (veya zaten oradaysa filtrelenir)
                    val currentRoute = navController.currentBackStackEntry?.destination?.route
                    if (currentRoute != "list") {
                        navController.navigate("list")
                    }
                },
                onDismiss       = {
                    scope.launch { cardsSheetState.hide() }
                        .invokeOnCompletion { showMyCardsSheet = false }
                }
            )
        }
    }

    // ── Premium Bottom Sheet ─────────────────────────────────────
    if (showPremiumSheet) {
        val plan by authViewModel.plan.collectAsStateWithLifecycle()
        ModalBottomSheet(
            onDismissRequest = { showPremiumSheet = false },
            sheetState       = premiumSheetState,
            containerColor   = Ink
        ) {
            PremiumSheet(
                currentPlan = plan,
                onDismiss   = {
                    scope.launch { premiumSheetState.hide() }
                        .invokeOnCompletion { showPremiumSheet = false }
                },
                onSubscribe = { /* TODO: Google Play Billing entegrasyonu */ }
            )
        }
    }
}

package com.mericucan.kampanyaradari.ui.screen

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.EditCalendar
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.domain.EntitlementRule
import com.mericucan.kampanyaradari.domain.EntitlementService
import com.mericucan.kampanyaradari.domain.SubscriptionPlan
import com.mericucan.kampanyaradari.store.CampaignTrackingStore
import com.mericucan.kampanyaradari.store.TrackingState
import com.mericucan.kampanyaradari.ui.component.EntitlementDialog
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.worker.ReminderScheduler
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

// ── Tarih biçimlendirici (Türkçe) ────────────────────────────
private val TR_DATE_FORMATTER = DateTimeFormatter.ofPattern("d MMMM yyyy", Locale("tr"))
private val ISO_FORMATTER     = DateTimeFormatter.ISO_LOCAL_DATE

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignDetailScreen(
    campaign: Campaign,
    trackingStore: CampaignTrackingStore,
    isFavorite: Boolean,
    favoriteCount: Int = 0,
    plan: SubscriptionPlan = SubscriptionPlan.FREE,
    isGuest: Boolean = false,
    activeReminderCount: Int = 0,
    onFavoriteClick: () -> Unit,
    onShowAuth: () -> Unit = {},
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope   = rememberCoroutineScope()

    var entitlementDialogRule by remember { mutableStateOf<EntitlementRule?>(null) }

    val trackingState by trackingStore.stateFor(campaign.id)
        .collectAsStateWithLifecycle(TrackingState())

    // DatePickerDialog görünürlüğü
    var showDatePicker           by remember { mutableStateOf(false) }
    var showNotifRationale       by remember { mutableStateOf(false) }

    // İzin launchers (Android 13+)
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) showDatePicker = true
        else scope.launch { trackingStore.clearReminder(campaign.id) }
    }

    // Toggle açıldığında izin kontrolü — önce temalı rationale, sonra sistem izni
    fun tryOpenDatePicker() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val ok = ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (ok) showDatePicker = true
            else    showNotifRationale = true   // sistem dialogu yerine önce bizimki
        } else {
            showDatePicker = true
        }
    }

    // ── DatePickerDialog ──────────────────────────────────────
    if (showDatePicker) {
        // Başlangıç: kayıtlı tarih varsa onu, yoksa kampanya bitiş tarihi, yoksa bugün+30
        val initMillis: Long = run {
            val stored = trackingState.reminderDateText
            if (stored.isNotEmpty()) {
                LocalDate.parse(stored, ISO_FORMATTER)
            } else {
                campaign.validToDate ?: LocalDate.now().plusDays(30)
            }
        }.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()

        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = initMillis,
            selectableDates = object : SelectableDates {
                override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                    // Bugün veya gelecekteki tarihler seçilebilir
                    val today = LocalDate.now()
                        .atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
                    return utcTimeMillis >= today
                }
            }
        )

        DatePickerDialog(
            onDismissRequest = {
                showDatePicker = false
                // Daha önce tarih seçilmemişse toggle'ı geri al
                if (trackingState.reminderDateText.isEmpty()) {
                    scope.launch { trackingStore.clearReminder(campaign.id) }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    val millis = datePickerState.selectedDateMillis
                    if (millis != null) {
                        val date    = Instant.ofEpochMilli(millis)
                            .atZone(ZoneOffset.UTC).toLocalDate()
                        val dateStr = date.format(ISO_FORMATTER)
                        scope.launch {
                            trackingStore.setReminderDate(campaign.id, dateStr)
                            trackingStore.setReminder(campaign.id, true)
                            ReminderScheduler.schedule(context, campaign.id, campaign.title, date)
                        }
                    }
                    showDatePicker = false
                }) {
                    Text("Tamam", color = DashboardGreen, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showDatePicker = false
                    if (trackingState.reminderDateText.isEmpty()) {
                        scope.launch { trackingStore.clearReminder(campaign.id) }
                    }
                }) {
                    Text("İptal", color = TextSecondary)
                }
            },
            colors = DatePickerDefaults.colors(
                containerColor = Ink
            )
        ) {
            DatePicker(
                state  = datePickerState,
                title  = {
                    Text(
                        "Puan son kullanma tarihi",
                        modifier = Modifier.padding(start = 24.dp, end = 12.dp, top = 16.dp),
                        color    = TextSecondary,
                        fontSize = 14.sp
                    )
                },
                headline = {
                    val selectedDate = datePickerState.selectedDateMillis?.let {
                        Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate()
                            .format(TR_DATE_FORMATTER)
                    } ?: "Tarih seçin"
                    Text(
                        selectedDate,
                        modifier   = Modifier.padding(start = 24.dp, bottom = 12.dp),
                        color      = DashboardGreen,
                        fontSize   = 28.sp,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = DatePickerDefaults.colors(
                    containerColor             = Ink,
                    titleContentColor          = TextSecondary,
                    headlineContentColor       = DashboardGreen,
                    weekdayContentColor        = TextSecondary,
                    subheadContentColor        = TextSecondary,
                    navigationContentColor     = TextPrimary,
                    yearContentColor           = TextPrimary,
                    currentYearContentColor    = DashboardGreen,
                    selectedYearContentColor   = NearBlack,
                    selectedYearContainerColor = DashboardGreen,
                    dayContentColor            = TextPrimary,
                    selectedDayContentColor    = NearBlack,
                    selectedDayContainerColor  = DashboardGreen,
                    todayContentColor          = DashboardGreen,
                    todayDateBorderColor       = DashboardGreen
                )
            )
        }
    }

    // ── Entitlement engel diyaloğu ───────────────────────────────
    entitlementDialogRule?.let { rule ->
        EntitlementDialog(
            title          = rule.title,
            message        = rule.message,
            isAuthRequired = rule.title == "Giriş gerekli",
            onDismiss      = { entitlementDialogRule = null },
            onShowAuth     = { entitlementDialogRule = null; onShowAuth() }
        )
    }

    // ── Bildirim izni rationale diyaloğu (temaya uygun) ──────────
    if (showNotifRationale) {
        androidx.compose.ui.window.Dialog(onDismissRequest = { showNotifRationale = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(24.dp))
                    .background(PanelBlack)
                    .padding(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // İkon
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(DashboardGreen.copy(alpha = 0.14f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.NotificationsActive,
                        contentDescription = null,
                        tint     = DashboardGreen,
                        modifier = Modifier.size(34.dp)
                    )
                }
                // Başlık
                androidx.compose.material3.Text(
                    "Bildirim İzni",
                    fontSize   = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    textAlign  = androidx.compose.ui.text.style.TextAlign.Center
                )
                // Açıklama
                androidx.compose.material3.Text(
                    "Kampanya bitiş tarihi hatırlatıcılarını alabilmek için bildirim iznine ihtiyacımız var.",
                    fontSize   = 14.sp,
                    color      = TextSecondary,
                    lineHeight = 20.sp,
                    textAlign  = androidx.compose.ui.text.style.TextAlign.Center
                )
                Spacer(Modifier.height(2.dp))
                // İzin Ver
                Button(
                    onClick = {
                        showNotifRationale = false
                        permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    androidx.compose.material3.Text(
                        "İzin Ver",
                        fontWeight = FontWeight.ExtraBold,
                        fontSize   = 15.sp
                    )
                }
                // Vazgeç
                Button(
                    onClick = {
                        showNotifRationale = false
                        scope.launch { trackingStore.clearReminder(campaign.id) }
                    },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = NearBlack,
                        contentColor   = TextSecondary
                    )
                ) {
                    androidx.compose.material3.Text(
                        "Vazgeç",
                        fontWeight = FontWeight.SemiBold,
                        fontSize   = 15.sp
                    )
                }
            }
        }
    }

    Scaffold(
        containerColor = NearBlack,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Detay",
                        color      = TextPrimary,
                        fontWeight = FontWeight.SemiBold,
                        fontSize   = 17.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Geri",
                            tint = TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = NearBlack)
            )
        },
        bottomBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(NearBlack)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
                    .navigationBarsPadding(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Button(
                    onClick  = {
                        when {
                            isFavorite -> onFavoriteClick() // kaldırma her zaman serbest
                            isGuest -> entitlementDialogRule = EntitlementRule(
                                false, "Giriş gerekli",
                                "Favorileri kaydetmek için hesap oluşturman veya giriş yapman gerekiyor."
                            )
                            plan.isPremiumLike -> onFavoriteClick()
                            favoriteCount < EntitlementService.FREE_FAVORITE_LIMIT -> onFavoriteClick()
                            else -> entitlementDialogRule = EntitlementRule(
                                false, "Favori limitine ulaştın",
                                "Free planda ${EntitlementService.FREE_FAVORITE_LIMIT} favori kampanya saklayabilirsin. Premium ile sınırsız favori ekleyebilirsin."
                            )
                        }
                    },
                    modifier = Modifier.weight(1f).height(52.dp),
                    shape    = RoundedCornerShape(999.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Icon(
                        if (isFavorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                        null, modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        if (isFavorite) "Favorilerimde" else "Favoriye ekle",
                        fontWeight = FontWeight.ExtraBold, fontSize = 14.sp, maxLines = 1
                    )
                }

                if (!campaign.sourceUrl.isNullOrEmpty()) {
                    Button(
                        onClick = {
                            val raw = campaign.sourceUrl ?: return@Button
                            // http/https öneki yoksa ekle
                            val url = if (raw.startsWith("http://") || raw.startsWith("https://"))
                                raw else "https://$raw"
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                            } catch (_: Exception) { /* tarayıcı bulunamadı */ }
                        },
                        modifier = Modifier.weight(1f).height(52.dp),
                        shape    = RoundedCornerShape(999.dp),
                        colors   = ButtonDefaults.buttonColors(
                            containerColor = DashboardGreen.copy(alpha = 0.15f),
                            contentColor   = DashboardGreen
                        )
                    ) {
                        Icon(Icons.Filled.OpenInBrowser, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Kaynak", fontWeight = FontWeight.ExtraBold, fontSize = 14.sp)
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // ── Hero görseli ───────────────────────────────────
            if (!campaign.imageUrl.isNullOrEmpty()) {
                AsyncImage(
                    model          = campaign.imageUrl,
                    contentDescription = campaign.title,
                    contentScale   = ContentScale.Crop,
                    modifier       = Modifier
                        .fillMaxWidth()
                        .height(220.dp)
                )
            }

            Column(modifier = Modifier.padding(horizontal = 20.dp, vertical = 20.dp)) {

                // ── Banka chip ────────────────────────────────
                Text(
                    campaign.displayBank,
                    fontSize   = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color      = DashboardGreen,
                    modifier   = Modifier
                        .background(DashboardGreen.copy(alpha = 0.1f), RoundedCornerShape(6.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                )

                Spacer(Modifier.height(12.dp))

                Text(
                    campaign.title,
                    fontSize   = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    lineHeight = 27.sp
                )

                Spacer(Modifier.height(8.dp))

                Text(
                    campaign.deadlineText,
                    fontSize   = 14.sp,
                    fontWeight = if (campaign.isUrgent) FontWeight.Bold else FontWeight.Normal,
                    color      = if (campaign.isUrgent) GoldLight else TextSecondary
                )

                Spacer(Modifier.height(16.dp))
                HorizontalDivider(color = BorderSubtle)
                Spacer(Modifier.height(16.dp))

                // ── Açıklama bloğu ────────────────────────────
                // Çok uzun description (yasal mevzuat dahil) varsa summary'e düş.
                // Summary de uzunsa kibarca kırp ve "tamamı kaynakta" notu ekle.
                val rawDesc    = campaign.description?.takeIf { it.isNotEmpty() }
                val rawSummary = campaign.summary?.takeIf { it.isNotEmpty() }
                val descPicked = when {
                    rawDesc != null && rawDesc.length > 500 && rawSummary != null -> rawSummary
                    rawDesc != null    -> rawDesc
                    rawSummary != null -> rawSummary
                    else               -> null
                }
                val descTruncated = (descPicked != null && descPicked.length > 500)
                val descFinal     = if (descTruncated) {
                    descPicked!!.take(450).trimEnd() + "…"
                } else descPicked

                val showSourceHint =
                    (rawDesc != null && rawDesc.length > 500) || descTruncated

                if (descFinal != null) {
                    Text(descFinal, fontSize = 14.sp, color = TextSecondary, lineHeight = 21.sp)

                    // Tam koşullar için kaynak yönlendirmesi
                    if (showSourceHint && !campaign.sourceUrl.isNullOrEmpty()) {
                        Spacer(Modifier.height(10.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(DashboardGreen.copy(alpha = 0.08f))
                                .border(
                                    1.dp,
                                    DashboardGreen.copy(alpha = 0.25f),
                                    RoundedCornerShape(10.dp)
                                )
                                .padding(horizontal = 12.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                Icons.Outlined.Info,
                                null,
                                tint     = DashboardGreen,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                "Kampanyanın tüm detayları ve yasal koşulları için aşağıdaki Kaynak butonunu kullan.",
                                fontSize   = 12.sp,
                                color      = TextSecondary,
                                lineHeight = 17.sp
                            )
                        }
                    }

                    Spacer(Modifier.height(24.dp))
                }

                // ── Ödül satırı ───────────────────────────────
                if (campaign.rewardType != null) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(GoldLight.copy(alpha = 0.08f))
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment     = Alignment.CenterVertically
                    ) {
                        Text("Ödül türü", fontSize = 13.sp, color = TextSecondary)
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment     = Alignment.CenterVertically
                        ) {
                            Text(
                                campaign.rewardType,
                                fontSize   = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                color      = GoldLight
                            )
                            val rv = campaign.rewardDisplayValue
                            if (rv.isNotEmpty()) {
                                Text(rv, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, color = GoldLight)
                            }
                        }
                    }
                    Spacer(Modifier.height(20.dp))
                }

                // ─────────────────────────────────────────────
                //  KAMPANYA TAKİBİ BÖLÜMÜ
                // ─────────────────────────────────────────────

                TrackingToggleCard(
                    isTracking = trackingState.isTracking,
                    onToggle   = { wantsOn ->
                        if (wantsOn) {
                            val rule = EntitlementService.canTrackCampaign(isGuest)
                            if (!rule.allowed) { entitlementDialogRule = rule; return@TrackingToggleCard }
                        }
                        scope.launch { trackingStore.setTracking(campaign.id, wantsOn) }
                    }
                )

                Spacer(Modifier.height(4.dp))

                AmountRow(
                    label         = "Harcadım",
                    value         = trackingState.spentText,
                    enabled       = trackingState.isTracking,
                    onValueChange = { scope.launch { trackingStore.setSpent(campaign.id, it) } }
                )

                Spacer(Modifier.height(4.dp))

                AmountRow(
                    label         = "Kazandım",
                    value         = trackingState.earnedText,
                    enabled       = trackingState.isTracking,
                    onValueChange = { scope.launch { trackingStore.setEarned(campaign.id, it) } }
                )

                Spacer(Modifier.height(4.dp))

                ReminderCard(
                    reminderEnabled  = trackingState.reminderEnabled,
                    trackingEnabled  = trackingState.isTracking,
                    reminderDateText = trackingState.reminderDateText,
                    onToggle = { wantsOn ->
                        if (wantsOn) {
                            // Önce takip açık olmalı
                            if (!trackingState.isTracking) return@ReminderCard
                            // Hatırlatıcı limiti kontrolü (bu kampanya henüz reminder eklememiş)
                            val rule = EntitlementService.canUseReminder(plan, activeReminderCount, isGuest)
                            if (!rule.allowed) { entitlementDialogRule = rule; return@ReminderCard }
                            scope.launch { trackingStore.setReminder(campaign.id, true) }
                            tryOpenDatePicker()
                        } else {
                            scope.launch {
                                trackingStore.clearReminder(campaign.id)
                                ReminderScheduler.cancelAll(context, campaign.id)
                            }
                        }
                    },
                    onEditDate = { tryOpenDatePicker() }
                )

                Spacer(Modifier.height(12.dp))

                StatusRow(
                    isTracking      = trackingState.isTracking,
                    reminderEnabled = trackingState.reminderEnabled
                )

                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

// ── Kampanya takibi toggle kartı ─────────────────────────────

@Composable
private fun TrackingToggleCard(isTracking: Boolean, onToggle: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(PanelBlack)
            .border(
                1.dp,
                if (isTracking) DashboardGreen.copy(alpha = 0.35f) else BorderSubtle,
                RoundedCornerShape(14.dp)
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text("Kampanya takibi", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
            Spacer(Modifier.height(4.dp))
            Text("Katılım, harcama ve kazancını burada tut.", fontSize = 12.sp, color = TextSecondary)
        }
        Switch(
            checked  = isTracking,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedThumbColor    = NearBlack,
                checkedTrackColor    = DashboardGreen,
                uncheckedThumbColor  = TextSecondary,
                uncheckedTrackColor  = Color.Transparent,
                uncheckedBorderColor = BorderSubtle
            )
        )
    }
}

// ── Harcadım / Kazandım satırı ────────────────────────────────

@Composable
private fun AmountRow(
    label: String,
    value: String,
    enabled: Boolean,
    onValueChange: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(PanelBlack)
            .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
            .padding(horizontal = 16.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Text(
            label,
            fontSize   = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color      = if (enabled) TextPrimary else TextSecondary
        )
        Row(
            verticalAlignment     = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (enabled) {
                BasicTextField(
                    value           = value,
                    onValueChange   = { new -> onValueChange(new.filter { it.isDigit() }) },
                    singleLine      = true,
                    cursorBrush     = SolidColor(DashboardGreen),
                    textStyle       = TextStyle(
                        fontSize   = 15.sp,
                        color      = TextPrimary,
                        fontWeight = FontWeight.SemiBold
                    ),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier        = Modifier.widthIn(min = 20.dp, max = 80.dp)
                )
            } else {
                Text(value.ifEmpty { "0" }, fontSize = 15.sp, color = TextSecondary, fontWeight = FontWeight.SemiBold)
            }
            Text("TL", fontSize = 13.sp, color = TextSecondary)
        }
    }
}

// ── Puan harcama hatırlatıcısı kartı ──────────────────────────

@Composable
private fun ReminderCard(
    reminderEnabled: Boolean,
    trackingEnabled: Boolean,
    reminderDateText: String,
    onToggle: (Boolean) -> Unit,
    onEditDate: () -> Unit
) {
    // Kayıtlı tarihin insan-okunur hali
    val formattedDate = remember(reminderDateText) {
        if (reminderDateText.isEmpty()) null
        else runCatching {
            LocalDate.parse(reminderDateText, ISO_FORMATTER).format(TR_DATE_FORMATTER)
        }.getOrNull()
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(PanelBlack)
            .border(
                1.dp,
                if (reminderEnabled) DashboardGreen.copy(alpha = 0.35f) else BorderSubtle,
                RoundedCornerShape(14.dp)
            )
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    "Puan harcama hatırlatıcısı",
                    fontSize   = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color      = if (trackingEnabled) TextPrimary else TextSecondary
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    "Katıldım seçiliyken son kullanımdan 7 gün, 3 gün ve son gün önce bildirim gönderirim.",
                    fontSize   = 12.sp,
                    color      = TextSecondary,
                    lineHeight = 17.sp
                )
            }
            Spacer(Modifier.width(12.dp))
            Switch(
                checked         = reminderEnabled,
                onCheckedChange = onToggle,
                enabled         = trackingEnabled,
                colors = SwitchDefaults.colors(
                    checkedThumbColor            = NearBlack,
                    checkedTrackColor            = DashboardGreen,
                    uncheckedThumbColor          = TextSecondary,
                    uncheckedTrackColor          = Color.Transparent,
                    uncheckedBorderColor         = BorderSubtle,
                    disabledUncheckedThumbColor  = TextSecondary.copy(alpha = 0.35f),
                    disabledUncheckedTrackColor  = Color.Transparent,
                    disabledUncheckedBorderColor = BorderSubtle.copy(alpha = 0.35f)
                )
            )
        }

        if (reminderEnabled) {
            Spacer(Modifier.height(10.dp))
            HorizontalDivider(color = BorderSubtle)
            Spacer(Modifier.height(10.dp))

            // Seçilen tarih + düzenle butonu
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment     = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        "Son kullanma tarihi",
                        fontSize = 11.sp,
                        color    = TextSecondary
                    )
                    Spacer(Modifier.height(2.dp))
                    Text(
                        formattedDate ?: "Tarih seçilmedi",
                        fontSize   = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color      = if (formattedDate != null) DashboardGreen else TextSecondary
                    )
                }
                TextButton(
                    onClick = onEditDate,
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Icon(
                        Icons.Outlined.EditCalendar,
                        null,
                        modifier = Modifier.size(15.dp),
                        tint     = DashboardGreen
                    )
                    Spacer(Modifier.width(4.dp))
                    Text("Değiştir", fontSize = 12.sp, color = DashboardGreen)
                }
            }

            Spacer(Modifier.height(6.dp))

            // Aktif hatırlatıcı sayısı
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Notifications,
                    null,
                    modifier = Modifier.size(13.dp),
                    tint     = DashboardGreen
                )
                Spacer(Modifier.width(4.dp))
                Text(
                    "3 hatırlatıcı planlandı  (7 gün · 3 gün · son gün)",
                    fontSize   = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = DashboardGreen
                )
            }
        }
    }
}

// ── Durum / Hatırlatma özeti ──────────────────────────────────

@Composable
private fun StatusRow(isTracking: Boolean, reminderEnabled: Boolean) {
    Row(
        modifier              = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        StatusCard("Durum",       if (isTracking)      "Takip ediliyor"  else "Takip edilmiyor", Modifier.weight(1f))
        StatusCard("Hatırlatma",  if (reminderEnabled) "Açık"            else "Kapalı",          Modifier.weight(1f))
    }
}

@Composable
private fun StatusCard(label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(PanelBlack)
            .border(1.dp, BorderSubtle, RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        Text(label, fontSize = 11.sp, color = TextSecondary)
        Spacer(Modifier.height(4.dp))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = TextPrimary)
    }
}

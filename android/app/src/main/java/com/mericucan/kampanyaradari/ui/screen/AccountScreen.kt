package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.CallMade
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Shield
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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.mericucan.kampanyaradari.domain.EntitlementService
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.viewmodel.AuthViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountScreen(
    authViewModel: AuthViewModel,
    favoriteCount: Int,
    myCardCount: Int,
    activeReminderCount: Int,
    onBack: () -> Unit,
    onShowAuth: () -> Unit,
    onShowPaywall: () -> Unit = {}
) {
    val isGuest     by authViewModel.isGuest.collectAsStateWithLifecycle()
    val displayName by authViewModel.displayName.collectAsStateWithLifecycle()
    val email       by authViewModel.email.collectAsStateWithLifecycle()
    val plan        by authViewModel.plan.collectAsStateWithLifecycle()
    val isLoading   by authViewModel.isLoading.collectAsStateWithLifecycle()

    var legalDocument by remember { mutableStateOf<LegalDocument?>(null) }

    val statusText = if (isGuest) "Misafir mod" else displayName
    val descriptionText =
        if (isGuest) "Misafir kullanım açık. Hesap bağlarsan favorilerin, kartların ve kazanç kayıtların cihazlar arasında taşınır."
        else "Favorilerin, kartların ve kazanç kayıtların hesabında saklanır."

    Scaffold(containerColor = NearBlack) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            // ── Geri butonu ────────────────────────────────────
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
                    "Geri",
                    tint     = TextPrimary,
                    modifier = Modifier.size(20.dp)
                )
            }

            // ── Başlık bloğu ────────────────────────────────────
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    "Hesap",
                    fontSize   = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color      = DashboardGreen
                )
                Text(
                    statusText,
                    fontSize   = if (statusText.contains("@")) 28.sp else 36.sp,
                    fontWeight = FontWeight.Black,
                    color      = TextPrimary,
                    lineHeight = if (statusText.contains("@")) 32.sp else 40.sp
                )
                if (!isGuest && !email.isNullOrEmpty() && email != statusText) {
                    Text(
                        email!!,
                        fontSize   = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color      = DashboardGreen
                    )
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    descriptionText,
                    fontSize   = 15.sp,
                    color      = TextPrimary.copy(alpha = 0.76f),
                    lineHeight = 21.sp
                )
            }

            // ── Durum kartı ─────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(24.dp))
                    .background(Color.White.copy(alpha = 0.08f))
                    .border(1.dp, Color.White.copy(alpha = 0.14f), RoundedCornerShape(24.dp))
                    .padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                AccountStatusRow(
                    icon  = Icons.Filled.CreditCard,
                    title = "Plan",
                    value = plan.displayName
                )
                AccountStatusRow(
                    icon  = Icons.Filled.NotificationsActive,
                    title = "Hatırlatıcı",
                    value = EntitlementService.reminderAllowanceText(plan, activeReminderCount)
                )
                AccountStatusRow(
                    icon  = Icons.Filled.Star,
                    title = "Favori",
                    value = EntitlementService.favoriteAllowanceText(plan, favoriteCount)
                )
                AccountStatusRow(
                    icon  = Icons.Filled.Campaign,
                    title = "Kart alarmı",
                    value = if (plan.isPremiumLike) "Aktif" else "Premium gerekli"
                )
            }

            // ── Premium kartı ───────────────────────────────────
            PremiumPreviewCard(onShowPaywall = onShowPaywall)

            // ── Yardım ve yasal bilgiler ────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(24.dp))
                    .background(Color.White.copy(alpha = 0.08f))
                    .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(24.dp))
                    .padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    "Yardım ve yasal bilgiler",
                    fontSize   = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary
                )
                AccountLinkButton(
                    icon     = Icons.Filled.Shield,
                    title    = "Gizlilik Politikası",
                    subtitle = "Hangi verileri neden kullandığımız",
                    onClick  = { legalDocument = LegalDocument.PRIVACY }
                )
                AccountLinkButton(
                    icon     = Icons.AutoMirrored.Filled.HelpOutline,
                    title    = "Destek",
                    subtitle = "Sık sorulan sorular ve yardım",
                    onClick  = { legalDocument = LegalDocument.SUPPORT }
                )
            }

            // ── Aksiyon butonları ───────────────────────────────
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                if (isGuest) {
                    Button(
                        onClick  = onShowAuth,
                        modifier = Modifier.fillMaxWidth().height(54.dp),
                        shape    = RoundedCornerShape(18.dp),
                        colors   = ButtonDefaults.buttonColors(
                            containerColor = DashboardGreen,
                            contentColor   = NearBlack
                        )
                    ) {
                        Icon(Icons.Filled.PersonAdd, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(
                            "Giriş ekranından hesap bağla",
                            fontSize   = 15.sp,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }
                }

                Button(
                    onClick = {
                        if (!isGuest) authViewModel.signOut()
                        onBack()
                    },
                    enabled  = !isLoading,
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape    = RoundedCornerShape(18.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = Color.White.copy(alpha = 0.10f),
                        contentColor   = TextPrimary,
                        disabledContainerColor = Color.White.copy(alpha = 0.06f)
                    )
                ) {
                    if (!isGuest) {
                        Icon(Icons.AutoMirrored.Filled.Logout, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                    }
                    Text(
                        if (isGuest) "Misafir moda dön" else "Çıkış yap ve misafir moda dön",
                        fontSize   = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(Modifier.height(8.dp))
        }
    }

    // ── Legal belge sheet ──────────────────────────────────────
    if (legalDocument != null) {
        ModalBottomSheet(
            onDismissRequest = { legalDocument = null },
            containerColor   = Ink
        ) {
            LegalDocumentContent(
                document  = legalDocument!!,
                onDismiss = { legalDocument = null }
            )
        }
    }
}

// ── Premium preview ─────────────────────────────────────────────

@Composable
private fun PremiumPreviewCard(onShowPaywall: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(DashboardGreen.copy(alpha = 0.13f))
            .border(1.dp, DashboardGreen.copy(alpha = 0.28f), RoundedCornerShape(24.dp))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(
            modifier              = Modifier.fillMaxWidth(),
            verticalAlignment     = Alignment.Top,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Premium", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Spacer(Modifier.height(4.dp))
                Text(
                    "Öncelikli hatırlatıcı, reklamsız kullanım ve gelişmiş kazanç raporları için hazır alan.",
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = TextPrimary.copy(alpha = 0.70f),
                    lineHeight = 18.sp
                )
            }
            Icon(
                Icons.Filled.AutoAwesome,
                null,
                tint     = DashboardGreen,
                modifier = Modifier.size(22.dp)
            )
        }
        Button(
            onClick  = onShowPaywall,
            modifier = Modifier.fillMaxWidth().height(50.dp),
            shape    = RoundedCornerShape(16.dp),
            colors   = ButtonDefaults.buttonColors(
                containerColor = DashboardGreen,
                contentColor   = NearBlack
            )
        ) {
            Icon(Icons.Filled.CreditCard, null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Premium seçeneklerini gör", fontSize = 15.sp, fontWeight = FontWeight.ExtraBold)
        }
    }
}

// ── Yardımcı composable'lar ─────────────────────────────────────

@Composable
private fun AccountStatusRow(
    icon: ImageVector,
    title: String,
    value: String
) {
    Row(
        modifier              = Modifier.fillMaxWidth(),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(DashboardGreen.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = DashboardGreen, modifier = Modifier.size(18.dp))
        }
        Column {
            Text(
                title,
                fontSize   = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color      = TextPrimary.copy(alpha = 0.58f)
            )
            Text(
                value,
                fontSize   = 16.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary,
                maxLines   = 2
            )
        }
    }
}

@Composable
private fun AccountLinkButton(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(DashboardGreen.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = DashboardGreen, modifier = Modifier.size(20.dp))
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
            Text(
                subtitle,
                fontSize   = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color      = TextPrimary.copy(alpha = 0.58f)
            )
        }
        Icon(
            Icons.AutoMirrored.Filled.CallMade,
            null,
            tint     = TextPrimary.copy(alpha = 0.62f),
            modifier = Modifier.size(16.dp)
        )
    }
}

// ── Legal belge içerikleri (iOS'tan birebir Türkçe metinler) ────

internal data class LegalSection(val title: String, val body: String)

internal enum class LegalDocument(
    val titleText: String,
    val subtitleText: String,
    val sections: List<LegalSection>
) {
    PRIVACY(
        titleText    = "Gizlilik Politikası",
        subtitleText = "Son güncelleme: 16 Mayıs 2026. Kampanya Radarı, banka ve kart kampanyalarını takip etmeyi kolaylaştıran bilgilendirme uygulamasıdır.",
        sections = listOf(
            LegalSection(
                "Toplanan veriler",
                "E-posta adresi ve giriş bilgisi hesap oluşturma ve oturum yönetimi için Supabase Auth üzerinden işlenir. Favoriler, Kartlarım tercihleri, kampanya katılım kayıtları, harcadım/kazandım tutarları ve hatırlatıcı tarihleri cihazda saklanır; kullanıcı giriş yaptığında Supabase ile senkronlanabilir."
            ),
            LegalSection(
                "Toplanmayan veriler",
                "Banka kartı numarası, banka hesabı, müşteri numarası veya banka şifresi toplanmaz. Uygulama finansal işlem yapmaz, kullanıcı adına harcama veya kampanya katılımı gerçekleştirmez."
            ),
            LegalSection(
                "Verilerin kullanım amacı",
                "Kampanyaları filtrelemek, favorileri ve kullanıcının kart tercihlerini göstermek; kampanya takibi, kazanç kaydı ve puan son kullanım hatırlatıcısı sunmak; Free ve Premium plan limitlerini uygulamak için kullanılır."
            ),
            LegalSection(
                "Üçüncü taraf hizmetler",
                "Supabase kimlik doğrulama ve senkron veriler için, Google Play Billing abonelik ve satın alma yönetimi için kullanılır. İleride reklam veya analitik SDK'sı eklenirse bu politika ve Play Store gizlilik cevapları güncellenecektir."
            ),
            LegalSection(
                "Kullanıcı hakları",
                "Kullanıcı hesabını, favorilerini, kart tercihlerini ve katılım kayıtlarını silme talebi gönderebilir. Destek ekranındaki bilgilerle iletişim kurulabilir."
            )
        )
    ),
    SUPPORT(
        titleText    = "Destek",
        subtitleText = "Banka ve kart kampanyalarını takip ederken ihtiyaç duyabileceğin temel yardım bilgileri.",
        sections = listOf(
            LegalSection(
                "Kampanya Radarı ne yapar?",
                "Banka ve kart kampanyalarını tek ekranda keşfetmene, favorilere almana, kendi kartlarına göre filtrelemene ve puan son kullanım hatırlatıcıları kurmana yardımcı olur."
            ),
            LegalSection(
                "Kampanyaya uygulama üzerinden katılabilir miyim?",
                "Hayır. Uygulama bilgilendirme ve takip aracıdır. Kampanyaya katılım için ilgili bankanın resmi sitesi veya mobil uygulaması kullanılmalıdır."
            ),
            LegalSection(
                "Banka bilgilerimi giriyor muyum?",
                "Hayır. Uygulama banka kartı numarası, banka hesabı, müşteri numarası veya banka şifresi istemez."
            ),
            LegalSection(
                "Hatırlatıcılar nasıl çalışır?",
                "Bir kampanyada Katıldım seçildiğinde puan son kullanım tarihi ve tutar girilebilir. Bildirim izni verilirse uygulama son kullanım tarihinden önce hatırlatma gönderebilir."
            ),
            LegalSection(
                "Destek talebi için hangi bilgiler gerekir?",
                "Cihaz modeli, Android sürümü, sorunun oluştuğu ekran, varsa ekran görüntüsü ve yaklaşık tarih/saat bilgisi destek sürecini hızlandırır."
            )
        )
    )
}

@Composable
private fun LegalDocumentContent(
    document: LegalDocument,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(top = 4.dp, bottom = 32.dp)
            .navigationBarsPadding(),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // Başlık
        Row(
            modifier              = Modifier.fillMaxWidth(),
            verticalAlignment     = Alignment.Top,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    "Kampanya Radarı",
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color      = DashboardGreen
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    document.titleText,
                    fontSize   = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary,
                    lineHeight = 32.sp
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

        Text(
            document.subtitleText,
            fontSize   = 14.sp,
            color      = TextPrimary.copy(alpha = 0.72f),
            lineHeight = 20.sp
        )

        document.sections.forEach { section ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(DashboardGreen.copy(alpha = 0.12f))
                    .border(1.dp, DashboardGreen.copy(alpha = 0.22f), RoundedCornerShape(18.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    section.title,
                    fontSize   = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color      = TextPrimary
                )
                Text(
                    section.body,
                    fontSize   = 13.sp,
                    color      = TextPrimary.copy(alpha = 0.68f),
                    lineHeight = 19.sp
                )
            }
        }
    }
}

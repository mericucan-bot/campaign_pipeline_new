package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.mericucan.kampanyaradari.R
import com.mericucan.kampanyaradari.ui.component.icon
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.viewmodel.CampaignCategory
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.GpsFixed

@Composable
fun OnboardingScreen(onFinish: () -> Unit) {
    var page by remember { mutableIntStateOf(0) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(NearBlack, Ink, NearBlack)))
    ) {
        AnimatedContent(
            targetState = page,
            transitionSpec = {
                slideInHorizontally { it } + fadeIn() togetherWith
                slideOutHorizontally { -it } + fadeOut()
            },
            label = "onboarding"
        ) { p ->
            when (p) {
                0 -> OnboardingPage1(onNext = { page = 1 })
                1 -> OnboardingPage2(onNext = { page = 2 })
                else -> OnboardingPage3(onFinish = onFinish)
            }
        }
    }
}

// ── Sayfa 1: Radar animasyonu ──────────────────────────────────

@Composable
private fun OnboardingPage1(onNext: () -> Unit) {
    val infiniteTransition = rememberInfiniteTransition(label = "radar")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(4000, easing = LinearEasing)),
        label = "sweep"
    )
    val pulse by infiniteTransition.animateFloat(
        initialValue = 0.7f, targetValue = 1.0f,
        animationSpec = infiniteRepeatable(tween(1500, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "pulse"
    )

    Column(modifier = Modifier.fillMaxSize()) {
        // Radar görsel — kalan tüm alanı kaplar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            contentAlignment = Alignment.Center
        ) {
            // ── iOS referansı: crosshair ızgara çizgileri ──────────
            Box(Modifier.width(360.dp).height(1.dp).background(DashboardGreen.copy(0.07f)))
            Box(Modifier.width(1.dp).height(360.dp).background(DashboardGreen.copy(0.07f)))

            // Radar halkaları
            Box(Modifier.size(360.dp).clip(CircleShape).border(1.dp, DashboardGreen.copy(0.10f), CircleShape))
            Box(Modifier.size(258.dp).clip(CircleShape).border(1.dp, DashboardGreen.copy(0.18f), CircleShape))
            Box(Modifier.size(154.dp).clip(CircleShape).border(1.dp, DashboardGreen.copy(0.30f), CircleShape))

            // Dönen süpürme çizgisi
            Box(Modifier.size(360.dp).rotate(rotation)) {
                Box(
                    modifier = Modifier
                        .width(180.dp).height(2.dp)
                        .align(Alignment.CenterEnd)
                        .background(Brush.horizontalGradient(listOf(Color.Transparent, DashboardGreen.copy(0.85f))))
                )
            }

            // Merkez nokta
            Box(Modifier.size((12 * pulse).dp).clip(CircleShape).background(DashboardGreen))

            // ── Halka üzeri blip noktaları (iOS referansı) ─────────
            Box(Modifier.offset(76.dp,   (-3).dp).size((5 * pulse).dp).clip(CircleShape).background(DashboardGreen.copy(0.85f)))
            Box(Modifier.offset((-22).dp, (-126).dp).size((5 * pulse).dp).clip(CircleShape).background(DashboardGreen.copy(0.70f)))
            Box(Modifier.offset(118.dp,   100.dp).size((4 * pulse).dp).clip(CircleShape).background(DashboardGreen.copy(0.75f)))
            Box(Modifier.offset((-110).dp, 158.dp).size((4 * pulse).dp).clip(CircleShape).background(DashboardGreen.copy(0.60f)))

            // ── 6 kategori chip — organik / asimetrik dağılım ──────
            // y offsetleri +20 dp aşağı kaydırılmış → aksiyon ekranın
            // görsel ortasına yakın düşüyor
            val chips = listOf(
                Triple(CampaignCategory.MARKET,      (-100).dp, (-130).dp),  // dış halka sol-üst
                Triple(CampaignCategory.FUEL,          (60).dp, (-115).dp),  // dış halka sağ-üst
                Triple(CampaignCategory.FASHION,     (-130).dp,   (45).dp),  // dış halka sol
                Triple(CampaignCategory.RESTAURANT,   (84).dp,   (75).dp),   // orta-dış halka sağ
                Triple(CampaignCategory.TRAVEL,       (-75).dp,  (150).dp),  // dış halka sol-alt
                Triple(CampaignCategory.ELECTRONICS,   (53).dp,  (168).dp)   // dış halka sağ-alt
            )
            chips.forEach { (category, x, y) ->
                Row(
                    modifier = Modifier
                        .offset(x, y)
                        .clip(RoundedCornerShape(999.dp))
                        .background(PanelBlack)
                        .border(1.dp, DashboardGreen.copy(0.45f), RoundedCornerShape(999.dp))
                        .padding(horizontal = 13.dp, vertical = 9.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector        = category.icon(),
                        contentDescription = null,
                        tint               = DashboardGreen,
                        modifier           = Modifier.size(24.dp)
                    )
                    Text(
                        text       = category.label,
                        fontSize   = 13.sp,
                        color      = TextPrimary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }

        // Alt metin — doğal yüksekliğini alır, boşluk bırakmaz
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .padding(top = 16.dp, bottom = 36.dp)
                .navigationBarsPadding()
        ) {
            OnboardingTextBlock(
                title     = "En İyi Fırsatları Yakala!",
                subtitle  = "Binlerce kampanya içinden sana en uygun olanları radarına al.",
                pageIndex = 0,
                button    = "İleri",
                onNext    = onNext
            )
        }
    }
}

// ── Sayfa 2: Tasarruf kumbarası görseli ──────────────────────

@Composable
private fun OnboardingPage2(onNext: () -> Unit) {
    val infiniteTransition = rememberInfiniteTransition(label = "jar")
    val float by infiniteTransition.animateFloat(
        initialValue = -8f, targetValue = 18f,
        animationSpec = infiniteRepeatable(tween(2200, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "float"
    )

    Column(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1.5f),
            contentAlignment = Alignment.Center
        ) {
            AsyncImage(
                model = R.drawable.onboarding_jar,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 20.dp)
                    .offset(y = (float * 2.5f).dp),
                contentScale = ContentScale.Fit
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 28.dp)
                .padding(bottom = 40.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            OnboardingTextBlock(
                title     = "Tasarruf Et, Kazan!",
                subtitle  = "Kaçırdığın fırsatları bul, birikimini artır, her alışverişte avantaj yakala.",
                pageIndex = 1,
                button    = "İleri",
                onNext    = onNext
            )
        }
    }
}

// ── Sayfa 3: Banka logoları görseli ──────────────────────────

@Composable
private fun OnboardingPage3(onFinish: () -> Unit) {
    Column(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1.5f),
            contentAlignment = Alignment.Center
        ) {
            AsyncImage(
                model = R.drawable.onboarding_banks,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 20.dp),
                contentScale = ContentScale.Fit
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 28.dp)
                .padding(bottom = 40.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            OnboardingTextBlock(
                title     = "Tüm Fırsatlar Radarında!",
                subtitle  = "Bankalardan kartlara, avantajlardan kampanyalara kadar aradığın her şey burada.",
                pageIndex = 2,
                button    = "Keşfetmeye başla",
                onNext    = onFinish
            )
        }
    }
}

// ── Ortak alt metin + navigasyon ─────────────────────────────

@Composable
private fun OnboardingTextBlock(
    title: String,
    subtitle: String,
    pageIndex: Int,
    button: String,
    onNext: () -> Unit
) {
    // ── Kampanya Radarı badge — iOS referansı: geniş, okunabilir ─
    Row(
        verticalAlignment     = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(PanelBlack)
            .border(1.5.dp, DashboardGreen.copy(0.55f), RoundedCornerShape(20.dp))
            .padding(horizontal = 22.dp, vertical = 16.dp)
    ) {
        Icon(
            imageVector        = Icons.Outlined.GpsFixed,
            contentDescription = null,
            tint               = DashboardGreen,
            modifier           = Modifier.size(38.dp)
        )
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(
                "Kampanya",
                fontSize      = 15.sp,
                color         = TextPrimary,
                fontWeight    = FontWeight.Medium,
                letterSpacing = 0.2.sp
            )
            Text(
                "RADARI",
                fontSize      = 20.sp,
                color         = DashboardGreen,
                fontWeight    = FontWeight.ExtraBold,
                letterSpacing = 3.sp,
                lineHeight    = 22.sp
            )
        }
    }

    Spacer(Modifier.height(16.dp))

    Text(title, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, color = TextPrimary, lineHeight = 34.sp)
    Spacer(Modifier.height(10.dp))
    Text(subtitle, fontSize = 15.sp, color = TextSecondary, lineHeight = 22.sp)
    Spacer(Modifier.height(28.dp))

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            repeat(3) { i ->
                Box(
                    modifier = Modifier
                        .height(8.dp)
                        .width(if (i == pageIndex) 24.dp else 8.dp)
                        .clip(CircleShape)
                        .background(if (i == pageIndex) DashboardGreen else TextSecondary.copy(0.3f))
                )
            }
        }

        Button(
            onClick = onNext,
            shape = RoundedCornerShape(999.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashboardGreen, contentColor = NearBlack),
            contentPadding = PaddingValues(horizontal = 28.dp, vertical = 14.dp)
        ) {
            Text(button, fontWeight = FontWeight.ExtraBold, fontSize = 16.sp)
        }
    }
}

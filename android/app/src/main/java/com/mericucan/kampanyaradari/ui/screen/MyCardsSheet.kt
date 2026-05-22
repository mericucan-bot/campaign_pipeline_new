package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mericucan.kampanyaradari.ui.component.bankBrandColor
import com.mericucan.kampanyaradari.ui.component.bankInitials
import com.mericucan.kampanyaradari.ui.theme.*

/**
 * Kartlarım yönetim sheet'i.
 * Kullanıcı hangi bankalara ait kartı olduğunu burada seçer.
 * Seçimler MyCardsStore'a kaydedilir ve kampanya listesinde
 * banka chip filtresi olarak kullanılır.
 */
@Composable
fun MyCardsSheet(
    allBanks: List<String>,
    bankLabel: (String) -> String,
    myCardBanks: Set<String>,
    onMyCardToggle: (String) -> Unit,
    onShowCampaigns: () -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
            .background(Ink)
    ) {
        // ── Başlık ────────────────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    "Kartlarım",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Text(
                    if (myCardBanks.isEmpty()) "Sahip olduğun bankaları seç"
                    else "${myCardBanks.size} kart kayıtlı",
                    fontSize = 13.sp,
                    color = if (myCardBanks.isEmpty()) TextSecondary else DashboardGreen
                )
            }
            IconButton(onClick = onDismiss) {
                Icon(Icons.Filled.Close, null, tint = TextSecondary)
            }
        }

        HorizontalDivider(color = BorderSubtle)

        // ── Banka listesi ─────────────────────────────────────
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 440.dp),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(allBanks) { bank ->
                BankCardRow(
                    bank       = bank,
                    label      = bankLabel(bank),
                    isSelected = myCardBanks.contains(bank),
                    onToggle   = { onMyCardToggle(bank) }
                )
            }
        }

        HorizontalDivider(color = BorderSubtle)

        // ── Alt buton alanı ───────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (myCardBanks.isNotEmpty()) {
                Button(
                    onClick = { onShowCampaigns(); onDismiss() },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Icon(Icons.Filled.CreditCard, null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Kartlarıma Özel Kampanyaları Göster",
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 14.sp
                    )
                }
            }

            TextButton(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Kapat", color = TextSecondary, fontSize = 14.sp)
            }
        }

        Spacer(Modifier.height(8.dp))
    }
}

// ── Banka satırı bileşeni ─────────────────────────────────────

@Composable
private fun BankCardRow(
    bank: String,
    label: String,
    isSelected: Boolean,
    onToggle: () -> Unit
) {
    val brandColor = bankBrandColor(bank)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(
                if (isSelected) brandColor.copy(alpha = 0.12f) else PanelBlack
            )
            .border(
                1.dp,
                if (isSelected) brandColor.copy(alpha = 0.55f) else BorderSubtle,
                RoundedCornerShape(14.dp)
            )
            .clickable { onToggle() }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Banka renk kutucuğu + baş harf
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(brandColor),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = bankInitials(label),
                fontSize = 16.sp,
                fontWeight = FontWeight.Black,
                color = Color.White
            )
        }

        // Banka adı
        Text(
            text = label,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isSelected) TextPrimary else TextSecondary,
            modifier = Modifier.weight(1f)
        )

        // Seçim göstergesi
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(brandColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(14.dp)
                )
            }
        } else {
            Icon(
                Icons.Outlined.RadioButtonUnchecked,
                contentDescription = null,
                tint = BorderSubtle,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

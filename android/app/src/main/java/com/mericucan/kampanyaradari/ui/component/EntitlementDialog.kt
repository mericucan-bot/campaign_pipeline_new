package com.mericucan.kampanyaradari.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.mericucan.kampanyaradari.ui.theme.*

/**
 * Entitlement engel diyaloğu.
 *
 * - [isAuthRequired] = true  → kilit ikonu + "Giriş Yap" + "Vazgeç" butonları
 * - [isAuthRequired] = false → sparkles ikonu + "Anladım" butonu
 */
@Composable
fun EntitlementDialog(
    title: String,
    message: String,
    isAuthRequired: Boolean = false,
    onDismiss: () -> Unit,
    onShowAuth: (() -> Unit)? = null
) {
    Dialog(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(PanelBlack)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ── İkon dairesi ──────────────────────────────────────
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(DashboardGreen.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isAuthRequired) Icons.Filled.Lock else Icons.Filled.AutoAwesome,
                    contentDescription = null,
                    tint     = DashboardGreen,
                    modifier = Modifier.size(30.dp)
                )
            }

            // ── Başlık ────────────────────────────────────────────
            Text(
                text       = title,
                fontSize   = 20.sp,
                fontWeight = FontWeight.Bold,
                color      = TextPrimary,
                textAlign  = TextAlign.Center
            )

            // ── Açıklama ──────────────────────────────────────────
            Text(
                text       = message,
                fontSize   = 14.sp,
                color      = TextSecondary,
                textAlign  = TextAlign.Center,
                lineHeight = 20.sp
            )

            // ── Butonlar ──────────────────────────────────────────
            if (isAuthRequired && onShowAuth != null) {
                Button(
                    onClick  = { onDismiss(); onShowAuth() },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Text("Giriş Yap / Hesap Oluştur", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                }
                Button(
                    onClick  = onDismiss,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = NearBlack,
                        contentColor   = TextPrimary
                    )
                ) {
                    Text("Vazgeç", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                }
            } else {
                Button(
                    onClick  = onDismiss,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape    = RoundedCornerShape(14.dp),
                    colors   = ButtonDefaults.buttonColors(
                        containerColor = DashboardGreen,
                        contentColor   = NearBlack
                    )
                ) {
                    Text("Anladım", fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                }
            }
        }
    }
}

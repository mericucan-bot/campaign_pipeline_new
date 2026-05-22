package com.mericucan.kampanyaradari.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColors = darkColorScheme(
    primary             = DashboardGreen,
    onPrimary           = NearBlack,
    primaryContainer    = DeepBlue,
    onPrimaryContainer  = DashboardGreen,
    secondary           = GoldLight,
    onSecondary         = NearBlack,
    secondaryContainer  = Color(0xFF1A1200),
    background          = NearBlack,
    onBackground        = TextPrimary,
    surface             = Ink,
    onSurface           = TextPrimary,
    surfaceVariant      = PanelBlack,
    onSurfaceVariant    = TextSecondary,
    outline             = BorderSubtle,
    error               = ErrorRed,
    onError             = NearBlack
)

@Composable
fun KampanyaRadariTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        typography  = KampanyaTypography,
        content     = content
    )
}

package com.mericucan.kampanyaradari.ui.component

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Checkroom
import androidx.compose.material.icons.filled.Devices
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.LocalGasStation
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.ui.graphics.vector.ImageVector
import com.mericucan.kampanyaradari.viewmodel.CampaignCategory

/**
 * Her kampanya kategorisi için profesyonel Material ikon eşleştirmesi.
 * UI katmanına özel olduğu için view-model paketinden ayrı bir yardımcı dosyada tutuluyor.
 */
fun CampaignCategory.icon(): ImageVector = when (this) {
    CampaignCategory.FUEL        -> Icons.Filled.LocalGasStation
    CampaignCategory.ELECTRONICS -> Icons.Filled.Devices
    CampaignCategory.FASHION     -> Icons.Filled.Checkroom
    CampaignCategory.MARKET      -> Icons.Filled.ShoppingCart
    CampaignCategory.ONLINE      -> Icons.Filled.Public
    CampaignCategory.RESTAURANT  -> Icons.Filled.Restaurant
    CampaignCategory.TRAVEL      -> Icons.Filled.Flight
}

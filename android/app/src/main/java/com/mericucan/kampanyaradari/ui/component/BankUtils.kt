package com.mericucan.kampanyaradari.ui.component

import androidx.compose.ui.graphics.Color

/**
 * Banka adından marka rengini döndürür.
 * [bank] parametresi Campaign.bank (ham DB değeri) alanıdır.
 *
 * Referans kartlar (2. resim):
 *  Maximum        → sıcak magenta/pembe   #D10066
 *  Axess/Akbank   → altın amber/turuncu   #F57C00
 *  Garanti BBVA   → koyu orman yeşili     #006B3C
 *  Paraf          → teal/cyan             #0097A7
 *  Sağlam Kart    → koyu teal             #00695C
 *  N Kolay        → koyu mavi             #1565C0
 *  ON Digital     → orta koyu yeşil       #2E7D32
 *  TEB            → koyu yeşil            #005C33
 *  VakıfBank/World→ amber turuncu         #FF8F00
 *  Yapı Kredi     → koyu lacivert         #1A237E
 */
fun bankBrandColor(bank: String): Color {
    val n = bank.lowercase()
        .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
        .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')
    return when {
        n.contains("garanti")                                           -> Color(0xFF006B3C)  // Garanti BBVA – koyu orman yeşili
        n.contains("maximum") || n.contains("isbank")
                              || n.contains("is bankasi")               -> Color(0xFFD10066)  // Maximum – sıcak magenta
        n.contains("axess")  || n.contains("akbank")                    -> Color(0xFFF57C00)  // Axess – altın amber
        n.contains("yapi kredi") || n.contains("yapikredi")
                              || n.contains("ykb")                      -> Color(0xFF1A237E)  // Yapı Kredi – koyu lacivert
        n.contains("denizbank") || n.contains("deniz")                  -> Color(0xFF1565C0)  // Denizbank – mavi
        n.contains("ziraat")                                            -> Color(0xFFB71C1C)  // Ziraat – kırmızı
        n.contains("halkbank") || n.contains("halk")                    -> Color(0xFF1B5E20)  // Halkbank – koyu yeşil
        n.contains("vakif")                                             -> Color(0xFFFF8F00)  // VakıfBank / Vakıf World – amber
        n.contains("teb")                                               -> Color(0xFF005C33)  // TEB – koyu yeşil
        n.contains("qnb") || n.contains("finansbank")                   -> Color(0xFF6A0032)  // QNB Finansbank – koyu kırmızı
        n.contains("paraf")                                             -> Color(0xFF0097A7)  // Paraf – teal/cyan
        n.contains("ing")                                               -> Color(0xFFE65100)  // ING – turuncu (Paraf'tan ayrı)
        n.contains("n kolay") || n.contains("nkolay")                   -> Color(0xFF1565C0)  // N Kolay – koyu mavi
        n.contains("on digital") || n.contains("ondigital")            -> Color(0xFF2E7D32)  // ON Digital – koyu yeşil
        n.contains("ptt")                                               -> Color(0xFF8D6E00)  // PTT – koyu sarı
        n.contains("hsbc")                                              -> Color(0xFFB71C1C)  // HSBC – kırmızı
        n.contains("saglam") || n.contains("saglamkart")               -> Color(0xFF00695C)  // Sağlam Kart – koyu teal
        n.contains("burgan")                                            -> Color(0xFF0D2B5E)  // Burgan Bank
        n.contains("sekerbank") || n.contains("seker")                 -> Color(0xFF9B0032)  // Şekerbank
        n.contains("fibabanka") || n.contains("fiba")                  -> Color(0xFF0054A3)  // Fibabanka
        else                                                            -> Color(0xFF1A3A5C)  // varsayılan
    }
}

/**
 * Banka adından kısa baş harf üretir.
 * [displayBank] parametresi Campaign.displayBank (görünen isim) alanıdır.
 */
fun bankInitials(displayBank: String): String {
    val t  = displayBank.trim()

    // Türkçe karakterleri normalize et
    val nl = t.lowercase()
        .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
        .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')

    if (nl.contains("teb")) return "T"
    if (nl.contains("qnb")) return "Q"
    if (t.length <= 3) return t.uppercase()

    return when {
        nl.contains("garanti")                                  -> "G"
        nl.contains("maximum")                                  -> "M"
        nl.contains("axess")                                    -> "A"
        nl.contains("paraf")                                    -> "P"
        nl.contains("vakif")                                    -> "V"
        nl.contains("deniz")                                    -> "D"
        nl.contains("ziraat")                                   -> "Z"
        nl.contains("halk")                                     -> "H"
        nl.contains("yapi") && nl.contains("kredi")             -> "YK"
        nl.contains("on digital") || nl.contains("ondigital")  -> "ON"
        nl.contains("n kolay")    || nl.contains("nkolay")     -> "N"
        nl.contains("saglam")                                   -> "SK"
        nl.contains("fibabanka")  || nl.contains("fiba")       -> "FB"
        nl.contains("akbank")                                   -> "AK"
        nl.contains("isbank")     || nl.contains("is bank")    -> "İŞ"
        nl.contains("burgan")                                   -> "BG"
        nl.contains("seker")                                    -> "ŞK"
        nl.contains("ing")                                      -> "ING"
        else -> t.take(2).uppercase()
    }
}

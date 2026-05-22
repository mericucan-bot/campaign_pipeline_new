package com.mericucan.kampanyaradari.ui.screen

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mericucan.kampanyaradari.ui.theme.*
import com.mericucan.kampanyaradari.viewmodel.AuthViewModel
import kotlinx.coroutines.delay

@Composable
fun AuthScreen(
    authViewModel: AuthViewModel,
    onDismiss: () -> Unit
) {
    val isLoading   by authViewModel.isLoading.collectAsState()
    val message     by authViewModel.authMessage.collectAsState()
    val isGuest     by authViewModel.isGuest.collectAsState()
    val displayName by authViewModel.displayName.collectAsState()
    val emailState  by authViewModel.email.collectAsState()

    // Giriş yapıldığında 1.5 sn sonra otomatik kapat
    val initialGuest = remember { isGuest }
    LaunchedEffect(isGuest) {
        if (initialGuest && !isGuest) {
            delay(1500)
            onDismiss()
        }
    }

    var isSignUp     by remember { mutableStateOf(false) }
    var email        by remember { mutableStateOf("") }
    var password     by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var showReset    by remember { mutableStateOf(false) }

    val passwordFocus = remember { FocusRequester() }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
            .background(Ink)
            .padding(horizontal = 24.dp, vertical = 20.dp)
    ) {
        Column {
            // ── Header ────────────────────────────────────────
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text("Hesap", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Text(
                        if (!isGuest) displayName else "E-posta ile giriş yap.",
                        fontSize = 13.sp,
                        color = if (!isGuest) DashboardGreen else TextSecondary
                    )
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Filled.Close, contentDescription = "Kapat", tint = TextSecondary)
                }
            }

            Spacer(Modifier.height(20.dp))

            if (!isGuest) {
                // ── Giriş yapılmış görünümü ───────────────────
                LoggedInContent(
                    displayName = displayName,
                    email       = emailState ?: "",
                    onSignOut   = { authViewModel.signOut() }
                )
            } else {
                // ── Tab switcher (Giriş / Kayıt) ──────────────
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(999.dp))
                        .background(PanelBlack)
                        .border(1.dp, DashboardGreen.copy(alpha = 0.3f), RoundedCornerShape(999.dp))
                        .padding(4.dp)
                ) {
                    listOf(false to "Giriş", true to "Kayıt").forEach { (value, label) ->
                        Button(
                            onClick = { isSignUp = value; showReset = false },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(999.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (isSignUp == value) DashboardGreen else androidx.compose.ui.graphics.Color.Transparent,
                                contentColor   = if (isSignUp == value) NearBlack else DashboardGreen
                            ),
                            elevation = ButtonDefaults.buttonElevation(0.dp, 0.dp, 0.dp)
                        ) {
                            Text(label, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                        }
                    }
                }

                Spacer(Modifier.height(20.dp))

                if (showReset) {
                    // ── Şifre sıfırlama ────────────────────────
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("E-posta") },
                        leadingIcon = { Icon(Icons.Filled.Email, null, tint = TextSecondary) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, imeAction = ImeAction.Done),
                        colors = authFieldColors()
                    )
                    Spacer(Modifier.height(16.dp))
                    Button(
                        onClick = { authViewModel.sendPasswordReset(email); showReset = false },
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = DashboardGreen, contentColor = NearBlack)
                    ) { Text("Sıfırlama Maili Gönder", fontWeight = FontWeight.Bold) }
                    TextButton(onClick = { showReset = false }) {
                        Text("← Geri dön", color = TextSecondary, fontSize = 13.sp)
                    }
                } else {
                    // ── E-posta alanı ──────────────────────────
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("E-posta") },
                        leadingIcon = { Icon(Icons.Filled.Email, null, tint = TextSecondary) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, imeAction = ImeAction.Next),
                        keyboardActions = KeyboardActions(onNext = { passwordFocus.requestFocus() }),
                        colors = authFieldColors()
                    )
                    Spacer(Modifier.height(12.dp))
                    // ── Şifre alanı ────────────────────────────
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Şifre") },
                        leadingIcon = { Icon(Icons.Filled.Lock, null, tint = TextSecondary) },
                        trailingIcon = {
                            IconButton(onClick = { showPassword = !showPassword }) {
                                Icon(
                                    if (showPassword) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                                    contentDescription = null, tint = TextSecondary
                                )
                            }
                        },
                        visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().focusRequester(passwordFocus),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(onDone = {
                            if (isSignUp) authViewModel.signUp(email, password)
                            else authViewModel.signIn(email, password)
                        }),
                        colors = authFieldColors()
                    )
                    if (!isSignUp) {
                        TextButton(onClick = { showReset = true }, modifier = Modifier.align(Alignment.End)) {
                            Text("Şifremi unuttum", color = TextSecondary, fontSize = 12.sp)
                        }
                    } else {
                        Spacer(Modifier.height(8.dp))
                    }
                    // ── Ana buton ──────────────────────────────
                    Button(
                        onClick = {
                            if (isSignUp) authViewModel.signUp(email, password)
                            else authViewModel.signIn(email, password)
                        },
                        enabled = !isLoading,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = DashboardGreen, contentColor = NearBlack)
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), color = NearBlack, strokeWidth = 2.dp)
                        } else {
                            Text(
                                if (isSignUp) "Hesap Oluştur" else "Giriş Yap",
                                fontWeight = FontWeight.ExtraBold, fontSize = 16.sp
                            )
                        }
                    }
                }

                // ── Mesaj alanı ────────────────────────────────
                message?.let { msg ->
                    Spacer(Modifier.height(12.dp))
                    val isPositive = msg.startsWith("Giriş başarılı") ||
                                     msg.startsWith("Hesap oluşturuldu") ||
                                     msg.startsWith("Şifre sıfırlama") ||
                                     msg.startsWith("📧 Kayıt alındı")
                    Text(
                        text = msg, fontSize = 13.sp,
                        color = if (isPositive) DashboardGreen else ErrorRed,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background((if (isPositive) DashboardGreen else ErrorRed).copy(alpha = 0.08f))
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                    )
                }

                Spacer(Modifier.height(16.dp))

                // ── Misafir devam et ───────────────────────────
                TextButton(
                    onClick = { authViewModel.continueAsGuest(); onDismiss() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Misafir olarak devam et →", color = TextSecondary, fontSize = 13.sp)
                }
            }

            // Klavye için padding
            WindowInsets.ime.asPaddingValues().let { Spacer(Modifier.height(it.calculateBottomPadding())) }
        }
    }
}

// ── Giriş yapılmış durumu ─────────────────────────────────────

@Composable
private fun LoggedInContent(
    displayName: String,
    email: String,
    onSignOut: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        // Kullanıcı bilgi kartı
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(DashboardGreen.copy(alpha = 0.08f))
                .border(1.dp, DashboardGreen.copy(alpha = 0.25f), RoundedCornerShape(16.dp))
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(CircleShape)
                        .background(DashboardGreen.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        displayName.take(1).uppercase(),
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = DashboardGreen
                    )
                }
                Column {
                    Text(displayName, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    if (email.isNotEmpty()) {
                        Text(email, fontSize = 12.sp, color = TextSecondary)
                    }
                }
            }
        }

        // Çıkış yap butonu
        OutlinedButton(
            onClick = onSignOut,
            modifier = Modifier.fillMaxWidth().height(50.dp),
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, ErrorRed.copy(alpha = 0.5f)),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = ErrorRed)
        ) {
            Icon(Icons.Filled.Logout, null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Çıkış Yap", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
        }

        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun authFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor      = DashboardGreen,
    unfocusedBorderColor    = BorderSubtle,
    focusedLabelColor       = DashboardGreen,
    unfocusedLabelColor     = TextSecondary,
    cursorColor             = DashboardGreen,
    focusedTextColor        = TextPrimary,
    unfocusedTextColor      = TextPrimary
)

package com.mericucan.kampanyaradari.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

// ── Response models ───────────────────────────────────────────

@Serializable
data class AuthUser(
    val id: String,
    val email: String? = null,
    @SerialName("user_metadata") val metadata: UserMetadata? = null
)

@Serializable
data class UserMetadata(
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("full_name") val fullName: String? = null,
    val name: String? = null
) {
    val bestDisplayName: String?
        get() = displayName?.takeIf { it.isNotBlank() }
            ?: fullName?.takeIf { it.isNotBlank() }
            ?: name?.takeIf { it.isNotBlank() }
}

@Serializable
data class AuthSession(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_at") val expiresAt: Long? = null,
    val user: AuthUser
)

@Serializable
data class SupabaseError(
    val error: String? = null,
    val message: String? = null,
    val msg: String? = null,
    @SerialName("error_description") val errorDescription: String? = null
) {
    val displayMessage: String
        get() = message?.takeIf { it.isNotBlank() }
            ?: errorDescription?.takeIf { it.isNotBlank() }
            ?: error?.takeIf { it.isNotBlank() }
            ?: "Bir hata oluştu."
}

// Supabase signUp bazen sadece user döner (email onayı açıksa), session olmadan
@Serializable
data class SignUpResponse(
    // Session alanları (email onayı kapalıysa)
    @SerialName("access_token") val accessToken: String? = null,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_at") val expiresAt: Long? = null,
    val user: AuthUser? = null,
    // Sadece kullanıcı alanları (email onayı açıksa)
    val id: String? = null,
    val email: String? = null,
    @SerialName("confirmation_sent_at") val confirmationSentAt: String? = null
)

// ── Service ───────────────────────────────────────────────────

class AuthService {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }
    private val JSON_MEDIA = "application/json; charset=utf-8".toMediaType()

    suspend fun signIn(email: String, password: String): AuthSession {
        return post(
            "${SupabaseConfig.URL}/auth/v1/token?grant_type=password",
            """{"email":"$email","password":"$password"}"""
        )
    }

    suspend fun signUp(email: String, password: String): AuthSession {
        val url = "${SupabaseConfig.URL}/auth/v1/signup"
        val bodyStr = """{"email":"$email","password":"$password"}"""
        val request = Request.Builder()
            .url(url)
            .addHeader("apikey", SupabaseConfig.ANON_KEY)
            .addHeader("Content-Type", "application/json")
            .post(bodyStr.toRequestBody(JSON_MEDIA))
            .build()

        val response = client.newCall(request).execute()
        val code = response.code
        val responseBody = response.use { it.body?.string() }
            ?: throw Exception("Sunucudan yanıt alınamadı.")

        if (code !in 200..299) {
            val err = runCatching { json.decodeFromString<SupabaseError>(responseBody) }.getOrNull()
            throw Exception(err?.displayMessage ?: "Kayıt başarısız. ($code)")
        }

        // Tam session varsa direkt kullan
        val signUpResp = runCatching { json.decodeFromString<SignUpResponse>(responseBody) }.getOrNull()

        if (signUpResp?.accessToken != null && signUpResp.user != null) {
            return AuthSession(
                accessToken  = signUpResp.accessToken,
                refreshToken = signUpResp.refreshToken,
                expiresAt    = signUpResp.expiresAt,
                user         = signUpResp.user
            )
        }

        // Email onayı bekleniyor — sahte session oluştur, kullanıcıya bildir
        val userId = signUpResp?.id ?: signUpResp?.user?.id ?: "pending"
        val userEmail = signUpResp?.email ?: email
        throw Exception("📧 Kayıt alındı! '$userEmail' adresine doğrulama maili gönderdik. Maili onayladıktan sonra giriş yapabilirsin.")
    }

    suspend fun refreshSession(refreshToken: String): AuthSession {
        return post(
            "${SupabaseConfig.URL}/auth/v1/token?grant_type=refresh_token",
            """{"refresh_token":"$refreshToken"}"""
        )
    }

    suspend fun sendPasswordReset(email: String) {
        val body = """{"email":"$email","redirect_to":"${SupabaseConfig.AUTH_REDIRECT_URL}"}"""
        val request = Request.Builder()
            .url("${SupabaseConfig.URL}/auth/v1/recover")
            .addHeader("apikey", SupabaseConfig.ANON_KEY)
            .addHeader("Content-Type", "application/json")
            .post(body.toRequestBody(JSON_MEDIA))
            .build()
        client.newCall(request).execute().close()
    }

    suspend fun signOut(accessToken: String) {
        val request = Request.Builder()
            .url("${SupabaseConfig.URL}/auth/v1/logout")
            .addHeader("apikey", SupabaseConfig.ANON_KEY)
            .addHeader("Authorization", "Bearer $accessToken")
            .post("".toRequestBody(JSON_MEDIA))
            .build()
        runCatching { client.newCall(request).execute().close() }
    }

    private fun post(url: String, bodyStr: String): AuthSession {
        val request = Request.Builder()
            .url(url)
            .addHeader("apikey", SupabaseConfig.ANON_KEY)
            .addHeader("Content-Type", "application/json")
            .post(bodyStr.toRequestBody(JSON_MEDIA))
            .build()

        val response = client.newCall(request).execute()
        val code = response.code
        val responseBody = response.use { it.body?.string() }
            ?: throw Exception("Sunucudan yanıt alınamadı.")

        if (code !in 200..299) {
            val err = runCatching { json.decodeFromString<SupabaseError>(responseBody) }.getOrNull()
            throw Exception(err?.displayMessage ?: "İşlem başarısız. ($code)")
        }

        return json.decodeFromString<AuthSession>(responseBody)
    }
}

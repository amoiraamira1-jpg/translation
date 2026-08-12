package com.example.screen_translator

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

/**
 * On-device translation via Google ML Kit Translate. This is free and has
 * no request limits/API key because the small language model is downloaded
 * once (Wi-Fi by default) and then runs entirely on the phone.
 */
object TranslateEngine {

    private var cached: Translator? = null
    private var cachedPair: Pair<String, String>? = null

    private fun clientFor(sourceCode: String, targetCode: String): Translator {
        val pair = sourceCode to targetCode
        if (cachedPair == pair && cached != null) return cached!!

        cached?.close()
        val options = TranslatorOptions.Builder()
            .setSourceLanguage(TranslateLanguage.fromLanguageTag(sourceCode) ?: TranslateLanguage.ENGLISH)
            .setTargetLanguage(TranslateLanguage.fromLanguageTag(targetCode) ?: TranslateLanguage.ARABIC)
            .build()
        val client = Translation.getClient(options)
        cached = client
        cachedPair = pair
        return client
    }

    /** Downloads the language model if needed, then translates [text]. */
    fun translate(
        text: String,
        sourceCode: String,
        targetCode: String,
        onResult: (String) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val client = clientFor(sourceCode, targetCode)
        val conditions = DownloadConditions.Builder().requireWifi().build()
        client.downloadModelIfNeeded(conditions)
            .addOnSuccessListener {
                client.translate(text)
                    .addOnSuccessListener { onResult(it) }
                    .addOnFailureListener { onError(it) }
            }
            .addOnFailureListener { onError(it) }
    }
}

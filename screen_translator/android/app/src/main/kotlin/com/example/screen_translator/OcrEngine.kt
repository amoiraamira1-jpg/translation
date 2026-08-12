package com.example.screen_translator

import android.graphics.Bitmap
import android.graphics.Rect
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions

/**
 * Runs Google ML Kit's on-device text recognizer over a captured screen
 * bitmap. This is free and works fully offline (no Cloud Vision key needed).
 *
 * To recognize Chinese / Japanese / Korean you must add the matching
 * `com.google.mlkit:text-recognition-*` dependency in build.gradle (see
 * README) and pick the right recognizer below based on Prefs.sourceLang().
 */
object OcrEngine {

    data class Block(val text: String, val box: Rect)

    private fun recognizerFor(langCode: String) = when (langCode) {
        "zh" -> TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build())
        "ja" -> TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build())
        "ko" -> TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
        "hi" -> TextRecognition.getClient(DevanagariTextRecognizerOptions.Builder().build())
        else -> TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    }

    /** Returns one [Block] per detected text line, each with its screen bounding box. */
    fun recognize(
        bitmap: Bitmap,
        sourceLangCode: String,
        onResult: (List<Block>) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)
        recognizerFor(sourceLangCode).process(image)
            .addOnSuccessListener { visionText: Text ->
                val blocks = mutableListOf<Block>()
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        if (line.text.isNotBlank()) blocks.add(Block(line.text, box))
                    }
                }
                onResult(blocks)
            }
            .addOnFailureListener { onError(it) }
    }
}

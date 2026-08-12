package com.example.screen_translator

import android.content.Context
import android.content.SharedPreferences

/**
 * Single source of truth for every toggle/slider in the Flutter settings
 * screens. The Flutter side writes to this via MainActivity's MethodChannel;
 * OverlayService (a native background service with no Flutter engine)
 * reads from it directly, so settings changes apply immediately without
 * restarting the floating icon.
 */
object Prefs {
    private const val NAME = "screen_translator_prefs"

    private fun sp(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    // Languages (BCP-47 / ML Kit language codes, e.g. "en", "ar", "ja")
    fun sourceLang(ctx: Context) = sp(ctx).getString("source_lang", "en") ?: "en"
    fun targetLang(ctx: Context) = sp(ctx).getString("target_lang", "ar") ?: "ar"
    fun setLanguages(ctx: Context, source: String, target: String) {
        sp(ctx).edit().putString("source_lang", source).putString("target_lang", target).apply()
    }

    // Floating icon settings (screenshot 3)
    fun iconSize(ctx: Context) = sp(ctx).getInt("icon_size", 35)
    fun iconTransparency(ctx: Context) = sp(ctx).getInt("icon_transparency", 20)
    fun autoMoveToEdge(ctx: Context) = sp(ctx).getBoolean("auto_move_edge", true)
    fun autoActivateRegionMode(ctx: Context) = sp(ctx).getBoolean("auto_region_mode", true)

    // Text style settings (screenshot 3)
    fun upcaseText(ctx: Context) = sp(ctx).getBoolean("upcase_text", false)
    fun textAlignCenter(ctx: Context) = sp(ctx).getBoolean("text_align_center", false)
    fun fontName(ctx: Context) = sp(ctx).getString("font_name", "Roboto-Medium") ?: "Roboto-Medium"

    // Other settings (screenshot 1)
    fun accessibilityMode(ctx: Context) = sp(ctx).getBoolean("accessibility_mode", false)
    fun oneTouchClose(ctx: Context) = sp(ctx).getBoolean("one_touch_close", true)
    fun hideCloseIcon(ctx: Context) = sp(ctx).getBoolean("hide_close_icon", true)
    fun hideSettingsIcon(ctx: Context) = sp(ctx).getBoolean("hide_settings_icon", true)
    fun originalTextVertical(ctx: Context) = sp(ctx).getBoolean("vertical_text", true)

    // Misc (screenshot 2 "More" menu)
    fun darkTheme(ctx: Context) = sp(ctx).getBoolean("dark_theme", true)

    fun putBool(ctx: Context, key: String, value: Boolean) =
        sp(ctx).edit().putBoolean(key, value).apply()

    fun putInt(ctx: Context, key: String, value: Int) =
        sp(ctx).edit().putInt(key, value).apply()

    fun putString(ctx: Context, key: String, value: String) =
        sp(ctx).edit().putString(key, value).apply()

    fun asMap(ctx: Context): Map<String, Any> = mapOf(
        "source_lang" to sourceLang(ctx),
        "target_lang" to targetLang(ctx),
        "icon_size" to iconSize(ctx),
        "icon_transparency" to iconTransparency(ctx),
        "auto_move_edge" to autoMoveToEdge(ctx),
        "auto_region_mode" to autoActivateRegionMode(ctx),
        "upcase_text" to upcaseText(ctx),
        "text_align_center" to textAlignCenter(ctx),
        "font_name" to fontName(ctx),
        "accessibility_mode" to accessibilityMode(ctx),
        "one_touch_close" to oneTouchClose(ctx),
        "hide_close_icon" to hideCloseIcon(ctx),
        "hide_settings_icon" to hideSettingsIcon(ctx),
        "vertical_text" to originalTextVertical(ctx),
        "dark_theme" to darkTheme(ctx),
    )
}

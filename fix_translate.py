path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

old_block = """  static Future<String> translate({
    required String text,
    required AppSettings settings,
  }) async {
    if (settings.engineId == 'microsoft') {
      return _translateWithMicrosoft(
        text: text,
        from: settings.sourceLang,
        to: settings.targetLang,
        apiKey: settings.microsoftApiKey,
        region: settings.microsoftRegion,
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    throw Exception(
      "${settings.engine.name} isn't connected to a backend yet. Add a "
      "Microsoft Translator key in Settings to try a live translation, or "
      "wire this engine's API in TranslationService the same way.",
    );
  }"""

new_block = """  static Future<String> translate({
    required String text,
    required AppSettings settings,
  }) async {
    if (settings.engineId == 'microsoft') {
      return _translateWithMicrosoft(
        text: text,
        from: settings.sourceLang,
        to: settings.targetLang,
        apiKey: settings.microsoftApiKey,
        region: settings.microsoftRegion,
      );
    }

    if (settings.engineId == 'google') {
      return _translateWithGoogleFree(
        text: text,
        from: settings.sourceLang,
        to: settings.targetLang,
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    throw Exception(
      "${settings.engine.name} isn't connected to a backend yet. Add a "
      "Microsoft Translator key in Settings to try a live translation, or "
      "wire this engine's API in TranslationService the same way.",
    );
  }

  static Future<String> _translateWithGoogleFree({
    required String text,
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Google Translate error \${response.statusCode}: \${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as List;
    final segments = decoded[0] as List;
    final buffer = StringBuffer();
    for (final seg in segments) {
      buffer.write((seg as List)[0]);
    }
    return buffer.toString();
  }"""

assert content.count(old_block) == 1, "translate() block not found or not unique"
content = content.replace(old_block, new_block, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE - google translate wired successfully")

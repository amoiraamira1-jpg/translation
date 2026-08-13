path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

marker = "  static Future<String> _translateWithMicrosoft({\n"
count = lines.count(marker)
assert count == 1, f"marker found {count} times, expected 1"
idx = lines.index(marker)

new_func = '''  static Future<String> _translateWithGoogleFree({
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
      throw Exception('Google Translate error: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as List;
    final segments = decoded[0] as List;
    final buffer = StringBuffer();
    for (final seg in segments) {
      buffer.write((seg as List)[0]);
    }
    return buffer.toString();
  }

'''

lines.insert(idx, new_func)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("DONE - function inserted successfully")

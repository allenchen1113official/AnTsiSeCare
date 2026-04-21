import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Claude API 自動翻譯服務
/// 將印尼語照護日誌備註翻譯為繁體中文供家屬閱讀
class TranslationService {
  static const String _apiEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  // API Key 從環境變數讀取（不寫在程式碼中）
  static String get _apiKey {
    const key = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
    return key;
  }

  /// 翻譯照護日誌備註：印尼語 → 繁體中文
  static Future<TranslationResult> translateCareNote({
    required String originalText,
    required String sourceLanguage,
    String targetLanguage = 'zh-TW',
  }) async {
    if (originalText.trim().isEmpty) {
      return TranslationResult(
        original: originalText,
        translated: '',
        success: true,
      );
    }

    final sourceLangName = _languageName(sourceLanguage);
    final targetLangName = _languageName(targetLanguage);

    final prompt = '''你是一位專業的長照照護翻譯員，擅長將照服員的照護紀錄翻譯成清楚易懂的語言。

請將以下$sourceLangName照護紀錄翻譯成$targetLangName。

翻譯規則：
1. 保留所有醫療數值（血壓、血糖、體溫等）
2. 長照術語使用台灣正式用語
3. 語氣自然，適合家屬閱讀
4. 若有異常症狀，保持原文的緊迫性
5. 只輸出翻譯結果，不加任何說明

原文：$originalText''';

    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': AppConstants.claudeModel,
          'max_tokens': AppConstants.claudeMaxTokens,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translated =
            (data['content'] as List).first['text'] as String;
        return TranslationResult(
          original: originalText,
          translated: translated.trim(),
          success: true,
        );
      } else {
        return TranslationResult(
          original: originalText,
          translated: originalText,
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return TranslationResult(
        original: originalText,
        translated: originalText,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 批次翻譯多筆照護備註
  static Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String sourceLanguage,
  }) async {
    final futures = texts.map((text) => translateCareNote(
          originalText: text,
          sourceLanguage: sourceLanguage,
        ));
    return Future.wait(futures);
  }

  static String _languageName(String code) {
    const names = {
      'zh-TW': '繁體中文',
      'id': '印尼語（Bahasa Indonesia）',
      'vi': '越南語',
      'th': '泰語',
      'en': '英語',
    };
    return names[code] ?? code;
  }
}

class TranslationResult {
  final String original;
  final String translated;
  final bool success;
  final String? error;

  const TranslationResult({
    required this.original,
    required this.translated,
    required this.success,
    this.error,
  });

  bool get hasTranslation => translated.isNotEmpty && translated != original;
}

// AI Chatbot service — temporarily disabled.
// Uncomment the block below when re-enabling the Gemini chat feature.

/*
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_strings.dart';

class GeminiMessage {
  final String role; // 'user' | 'model'
  final String text;
  const GeminiMessage({required this.role, required this.text});
}

class GeminiService {
  final List<GeminiMessage> _history = [];

  List<GeminiMessage> get history => List.unmodifiable(_history);

  Future<String> sendMessage(String userMessage) async {
    _history.add(GeminiMessage(role: 'user', text: userMessage));

    final contents = [
      {
        'role': 'user',
        'parts': [{'text': AppStrings.geminiSystemPrompt}],
      },
      ..._history.map((m) => {
            'role': m.role,
            'parts': [{'text': m.text}],
          }),
    ];

    try {
      final response = await http.post(
        Uri.parse('${AppStrings.geminiEndpoint}?key=${AppStrings.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'I could not understand that. Please try again.';
        _history.add(GeminiMessage(role: 'model', text: text));
        return text;
      } else {
        debugPrint('Gemini error: ${response.body}');
        return 'Sorry, I am having trouble connecting. Please try again later.';
      }
    } catch (e) {
      debugPrint('Gemini exception: $e');
      return 'Sorry, I could not connect to the AI service.';
    }
  }

  void clearHistory() => _history.clear();
}
*/

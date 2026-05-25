import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toApiFormat() => {
    'role': role,
    'content': content,
  };
}

class ClaudeService {
  static const _apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const _endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  static final ClaudeService _instance = ClaudeService._internal();
  factory ClaudeService() => _instance;
  ClaudeService._internal();

  final List<ChatMessage> _conversationHistory = [];
  
  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);

  static const String _systemPrompt = '''You are TaxiMate, a friendly and knowledgeable AI companion for South African taxi commuters. You help with:

1. **Fare Calculations**: Help users estimate taxi fares. Base fare is R15, plus R12 per kilometer. Peak hours (6-9 AM, 4-7 PM) add 30% surge.

2. **Route Planning**: Suggest efficient routes between popular locations like JHB CBD, Soweto, Sandton, Alexandra, Pretoria, Cape Town, and Durban areas.

3. **Safety Tips**: Provide commuter safety advice for minibus taxis.

4. **Local Knowledge**: Share information about taxi ranks, routes, and travel times between destinations.

5. **Budget Planning**: Help users plan their weekly/monthly transport budgets.

Keep responses concise, friendly, and relevant to South African taxi commuting. Use Rand (R) for currency. Be helpful and conversational like a local friend who knows the taxi system well.

When calculating fares:
- Base fare: R15
- Per kilometer: R12
- Peak hour surge: +30%
- Typical distances: JHB CBD to Soweto ~15km, Sandton to Alex ~5km, JHB to Pretoria ~55km''';

  void clearHistory() {
    _conversationHistory.clear();
  }

  Future<String> sendMessage(String userMessage) async {
    if (_apiKey.isEmpty || _endpoint.isEmpty) {
      return "AI service is not configured. Please contact support.";
    }

    _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));

    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ..._conversationHistory.map((m) => m.toApiFormat()),
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        
        _conversationHistory.add(ChatMessage(
          role: 'assistant',
          content: assistantMessage,
        ));
        
        return assistantMessage;
      } else {
        debugPrint('Claude API Error: ${response.statusCode} - ${response.body}');
        _conversationHistory.removeLast();
        return "Sorry, I couldn\'t process that request. Please try again.";
      }
    } catch (e) {
      debugPrint('Claude Service Error: $e');
      _conversationHistory.removeLast();
      return "Connection error. Please check your internet and try again.";
    }
  }

  /// Quick fare calculation helper
  String getQuickFareEstimate(double distanceKm, bool isPeakHour) {
    const baseFare = 15.0;
    const perKm = 12.0;
    const peakSurge = 1.3;
    
    double fare = baseFare + (distanceKm * perKm);
    if (isPeakHour) fare *= peakSurge;
    
    return 'R${fare.toStringAsFixed(2)}';
  }
}

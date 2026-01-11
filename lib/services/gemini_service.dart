import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Initialize Gemini with the API key
  static const String _apiKey = 'AIzaSyBDlmB4m1SlxiGw_H0eQ70OchnyWyfXUzc';
  late final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
  );

  /// Generate a response using Gemini AI directly
  Future<String> generateResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini AI');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Generate safety advice for women
  Future<String> getSafetyAdvice(String situation) async {
    final prompt = '''
You are a safety assistant for women. Provide practical, helpful advice for the following situation:

Situation: $situation

Please provide:
1. Immediate safety steps
2. Prevention tips
3. Emergency contacts to consider
4. General safety recommendations

Keep the response concise but comprehensive, and prioritize safety above all else.
''';

    return await generateResponse(prompt);
  }

  /// Generate emergency response plan
  Future<String> getEmergencyPlan(String location, String threatType) async {
    final prompt = '''
Create an emergency response plan for a woman in danger:

Location: $location
Threat type: $threatType

Provide a step-by-step emergency plan including:
1. Immediate actions to take
2. How to call for help
3. Safe escape routes if applicable
4. What to do after escaping
5. How to document the incident

Focus on practical, actionable steps that prioritize personal safety.
''';

    return await generateResponse(prompt);
  }

  /// Get self-defense tips
  Future<String> getSelfDefenseTips(String scenario) async {
    final prompt = '''
Provide self-defense tips for women in the following scenario:

Scenario: $scenario

Include:
1. Physical defense techniques
2. Verbal de-escalation strategies
3. Awareness and prevention tips
4. Use of personal safety devices
5. When to seek professional help

Emphasize that self-defense is about awareness and prevention, not just physical confrontation.
''';

    return await generateResponse(prompt);
  }
}

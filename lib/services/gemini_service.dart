import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'flora_context_service.dart';

class GeminiService {
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      debugPrint('❌ GEMINI_API_KEY not found in .env file');
    }
    return key;
  }
  final GenerativeModel _model;
  
  final String modelName;

  static Future<bool> testConnection() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
      );
      final response = await model.generateContent([Content.text("ping")]).timeout(const Duration(seconds: 30));
      return response.text != null;
    } catch (e) {
      debugPrint("Error in testConnection: ${e.toString()}");
      return false;
    }
  }

  GeminiService()
      : modelName = 'gemini-2.5-flash',
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: geminiApiKey,
          systemInstruction: Content.system(
              "You are Flora, the AI plant companion inside Digital Conservatory. You know the user's entire plant collection and home conditions.\n\nRules you always follow:\n- Always speak in first person. Never say 'Flora thinks' or 'Flora suggests' — say 'I think' and 'I suggest'.\n- Never self-identify at the end of responses. Do not add 'I'm Flora and I'm here to help!' or similar.\n- Keep responses to 80–120 words maximum unless the user explicitly asks for more detail.\n- Ask at most one follow-up question per response.\n- Address the user by name when you know it.\n- Reference their specific plants by name when relevant.\n- Never use endearments like 'dear', 'lovely', 'darling'.\n- No bold text, headers, or bullet lists in conversational responses. Write in plain flowing sentences.\n- Use emoji sparingly — maximum 2 per message, only 🌿 💧 🌱 ☀️.\n- When the user's plant data is available, give specific advice for that plant rather than generic advice.\n- Always respond in the same language the user writes in."),
        );

  Future<String> askFlora(
      List<Map<String, String>> previousMessages, String newMsg) async {
    try {
      final history = previousMessages.map((m) {
        final role = m['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(m['text'] ?? '')]);
      }).toList();

      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(newMsg)).timeout(const Duration(seconds: 30));
      return response.text ??
          "Sorry I could not connect right now. Please try again.";
    } catch (e) {
      debugPrint("Error in askFlora: ${e.toString()}");
      return "Sorry I could not connect right now. Please try again.";
    }
  }

  Future<String> generatePersonalizedWeeklyPlan(List<Map<String, dynamic>> plants) async {
    try {
      final plantDescriptions = plants.map((p) {
        final name = p['name'] ?? 'Unknown plant';
        final category = p['category'] ?? 'Unknown category';
        final health = p['healthStatus'] ?? 'Unknown health';
        final zone = p['zone'] ?? 'Unknown zone';
        return "- $name (Category: $category, Health: $health, Zone: $zone)";
      }).join("\n");

      final prompt = '''
You are Flora, an expert plant care companion. I need a structured 7-day care schedule for my specific plants.
Here are my plants:
$plantDescriptions

Please create a day-by-day weekly care plan (Monday to Sunday) for these plants.
Provide practical advice, watering tips, and any specific attention they need based on their health status and zone.
Write it as plain readable text, no markdown. Use simple emojis for visual flair. Keep it engaging but concise.
''';

      final response = await _model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
      return response.text ?? "I could not generate a plan at this time.";
    } catch (e) {
      debugPrint("Error in generatePersonalizedWeeklyPlan: ${e.toString()}");
      return "Sorry, I could not generate your plan right now. Please try again.";
    }
  }

  /// Sends a plain prompt to Gemini without the Flora persona system instruction,
  /// used for structured outputs like the 7-day care schedule where the word-limit
  /// and conversational persona would break the format.
  Future<String> generateWeeklySchedule(String prompt) async {
    try {
      final planModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
      );
      final response = await planModel
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 45));
      return response.text?.trim() ?? '';
    } catch (e) {
      debugPrint('Error in generateWeeklySchedule: ${e.toString()}');
      return '';
    }
  }


  Future<String> generatePlantEulogy({
    required String plantName,
    required String category,
    required int daysCaredFor,
    required int totalWaterings,
    required int totalGrowthEntries,
    required String memorialNote,
  }) async {
    try {
      final prompt = '''
You are a warm, compassionate gardener writing a short eulogy for a plant that has passed away.
The plant was a $category named $plantName.
It was cared for for $daysCaredFor days, watered $totalWaterings times, and had $totalGrowthEntries journal entries.
The owner left this memorial note: "$memorialNote".
Write a heartfelt 3-sentence eulogy. Reference the care and data softly, and end with a comforting thought.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      return response.text ?? 'May this plant rest peacefully in the soil.';
    } catch (e) {
      debugPrint("Error generating eulogy: ${e.toString()}");
      return 'May $plantName rest peacefully in the soil, returning to the earth after $daysCaredFor days of care.';
    }
  }

  Future<String> generateCommunityAnswer(String postTitle, String postBody, String postCategory) async {
    try {
      final prompt = '''
You are Flora, the AI plant expert for the Digital Conservatory app community. 
A user has posted a question and you need to provide a helpful expert answer. 
Post title: $postTitle
Post content: $postBody
Write a warm practical and specific answer of 2 to 4 sentences. 
Start with directly addressing their specific situation. Give one concrete actionable recommendation. End with an encouraging note. Do not use bullet points. Write as if you are a knowledgeable friend not a robot. Return only the answer text with no preamble.
''';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      return response.text?.trim() ?? 'I recommend keeping a close eye on it and adjusting your care routine slightly. Let us know how it progresses!';
    } catch (e) {
      debugPrint("Error generating community answer: ${e.toString()}");
      return 'That sounds like an interesting challenge! I hope the community here can share some great advice soon.';
    }
  }

  Future<String> generatePlantPassportSummary(
    String plantName,
    String category,
    int daysCaredFor,
    int totalWaterings,
    int totalGrowthEntries,
    int currentHealthScore,
    bool hasDisease,
    bool diseaseResolved,
  ) async {
    try {
      final prompt = '''
You are an expert plant appraiser. Please write a 2 sentence trustworthy and factual summary of this plant suitable for a trading marketplace listing.
Plant details:
Name: $plantName
Category: $category
Days in care: $daysCaredFor
Total waterings: $totalWaterings
Journal entries: $totalGrowthEntries
Current health score (out of 100): $currentHealthScore
Disease history: ${hasDisease ? (diseaseResolved ? 'Recovered from past issue' : 'Currently has an active issue') : 'Clean record'}

The summary should mention how long it has been cared for, its current health, and one positive characteristic. Return only the text with no preamble.
''';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      return response.text?.trim() ?? 'A well-loved $plantName cared for over $daysCaredFor days with a health score of $currentHealthScore. It is ready for its next home.';
    } catch (e) {
      debugPrint("Error generating passport summary: ${e.toString()}");
      return 'A beautiful $plantName cared for over $daysCaredFor days. A great addition to any collection.';
    }
  }

  /// Sends a message with a deeply personalised system prompt built from the
  /// user's live plant data. This is the preferred method for all text chat.
  Future<String> askFloraWithContext(
    List<Map<String, String>> previousMessages,
    String newMessage,
    String userUid, {
    String conversationId = '',
  }) async {
    // Guard: check API key is configured
    if (geminiApiKey == 'PASTE_YOUR_KEY_HERE') {
      debugPrint(
          '⚠️  FLORA ERROR: Gemini API key is not configured. '
          'Please add your GEMINI_API_KEY to the .env file.');
      return 'Flora is not configured. Please add your Gemini API key to the .env file.';
    }

    try {
      // 1. Build the rich context document for this user
      final context = await FloraContextService().buildContext(userUid, conversationId);

      // 2. Compose the enhanced, personalised system prompt
      final enhancedSystemPrompt = '''
You are Flora, the AI plant companion inside Digital Conservatory. You know the user's entire plant collection and home conditions.

Rules you always follow:
- Always speak in first person. Never say 'Flora thinks' or 'Flora suggests' — say 'I think' and 'I suggest'.
- Never self-identify at the end of responses. Do not add 'I'm Flora and I'm here to help!' or similar.
- Keep responses to 80–120 words maximum unless the user explicitly asks for more detail.
- Ask at most one follow-up question per response.
- Address the user by name when you know it.
- Reference their specific plants by name when relevant.
- Never use endearments like 'dear', 'lovely', 'darling'.
- No bold text, headers, or bullet lists in conversational responses. Write in plain flowing sentences.
- Use emoji sparingly — maximum 2 per message, only 🌿 💧 🌱 ☀️.
- When the user's plant data is available, give specific advice for that plant rather than generic advice.
- Always respond in the same language the user writes in.

Here is everything you know about this user and their plants right now:

$context

Reference their specific plants by name when relevant. Be proactive but concise. Never give generic advice when you have their actual data.''';

      // 3. Build a context-aware model for this request
      final contextModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
        systemInstruction: Content.system(enhancedSystemPrompt),
      );

      // 4. Replay history and send the new message
      final history = previousMessages.map((m) {
        final role = m['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(m['text'] ?? '')]);
      }).toList();

      final chat = contextModel.startChat(history: history);
      final response = await chat.sendMessage(Content.text(newMessage)).timeout(const Duration(seconds: 30));
      return response.text ??
          'Sorry, I could not connect right now. Please try again.';
    } catch (e, stackTrace) {
      debugPrint("❌ Flora askFloraWithContext error: ${e.toString()}");
      debugPrint("Stack trace:\n$stackTrace");
      return 'Sorry, I could not connect right now. Please try again.';
    }
  }

  /// Maps a BCP-47 language code to a full language name for the Gemini prompt.
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'pt': 'Portuguese',
    'ar': 'Arabic',
    'fa': 'Farsi',
    'ja': 'Japanese',
    'ko': 'Korean',
    'it': 'Italian',
    'nl': 'Dutch',
    'tr': 'Turkish',
    'pl': 'Polish',
    'sv': 'Swedish',
    'hi': 'Hindi',
  };

  Future<String> analyzeePlantImage(
    File image, [
    String? question,
    String languageCode = 'en',
  ]) async {
    try {
      final languageName = _languageNames[languageCode] ?? 'English';
      const basePrompt =
          'You are a professional botanist and plant health expert. Analyze this plant image and respond in this exact format — no asterisks, no markdown, no bullet characters, no section headers with colons:\n\n'
          'Plant identified: [common name] ([scientific name])\n'
          'Health score: [number between 0-100]\n'
          'Status: [Healthy / Needs Attention / Critical]\n'
          'What I can see: [2-3 sentences describing the plant\'s condition in plain English]\n'
          'Most urgent action: [one specific thing the user should do this week]\n'
          'Care tip: [one practical care tip specific to this species]\n\n'
          'Keep the entire response under 150 words. Do not use asterisks, dashes as bullets, or ALL CAPS headers. Write in plain conversational English as if speaking directly to the plant owner.';
      final questionSuffix = question != null ? '\n\nAlso answer this question: $question' : '';
      final prompt = '$basePrompt$questionSuffix Please provide your entire response in the following language: $languageName.';
      final imageBytes = await image.readAsBytes();

      // Simple MIME type derivation or default to jpeg
      final path = image.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (path.endsWith('.heic')) {
        mimeType = 'image/heic';
      } else if (path.endsWith('.heif')) {
        mimeType = 'image/heif';
      }

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      return response.text ??
          "Sorry I could not connect right now. Please try again.";
    } catch (e) {
      debugPrint("Error in analyzeePlantImage: ${e.toString()}");
      return "Sorry I could not connect right now. Please try again.";
    }
  }

  /// Downloads a growth journal image from [imageUrl] and asks Gemini to
  /// produce a structured JSON health assessment for [plantName].
  /// Returns a [Map<String, dynamic>] with keys:
  ///   overallScore, condition, observations, newGrowthDetected,
  ///   issuesDetected, recommendations.
  Future<Map<String, dynamic>> analyzeGrowthPhoto({
    required String imageUrl,
    required String plantName,
    required String previousHealthStatus,
  }) async {
    // Safe fallback used whenever something goes wrong
    Map<String, dynamic> fallback() => {
          'overallScore': 70,
          'condition': 'Healthy',
          'observations': 'Unable to analyze photo automatically.',
          'newGrowthDetected': false,
          'issuesDetected': <String>[],
          'recommendations': 'Continue regular care.',
        };

    try {
      // 1. Download the image bytes
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return fallback();
      final imageBytes = response.bodyBytes;

      // 2. Detect MIME type from URL
      final lowerUrl = imageUrl.toLowerCase();
      String mimeType = 'image/jpeg';
      if (lowerUrl.contains('.png')) {
        mimeType = 'image/png';
      } else if (lowerUrl.contains('.webp')) {
        mimeType = 'image/webp';
      }

      // 3. Build the structured JSON prompt
      final prompt = '''
You are a plant health expert analyzing a growth journal photo.
The plant is called "$plantName" and its last recorded health status was "$previousHealthStatus".

Please analyze this photo carefully and respond ONLY with a valid JSON object 
containing exactly these fields:
- "overallScore": integer 0-100 (100 = perfect health)
- "condition": one of "Thriving", "Healthy", "Needs Attention", "Critical"
- "observations": 1-2 sentences describing what you visually observe (growth signs, leaf color, stem condition, any concerns)
- "newGrowthDetected": boolean, true if you can see new leaves, shoots, or growth
- "issuesDetected": array of strings naming visible problems (e.g. "yellowing", "spots", "drooping", "pests") — empty array if none
- "recommendations": 1 sentence with the single most important action the user should take right now

Respond with JSON only. No markdown. No explanation.''';

      // 4. Call Gemini with the image
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final geminiResponse = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      final raw = geminiResponse.text ?? '';

      // 5. Strip possible markdown code fences and parse
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      // Normalise types defensively
      return {
        'overallScore': (decoded['overallScore'] as num?)?.toInt() ?? 70,
        'condition': decoded['condition']?.toString() ?? 'Healthy',
        'observations': decoded['observations']?.toString() ?? '',
        'newGrowthDetected': decoded['newGrowthDetected'] == true,
        'issuesDetected': (decoded['issuesDetected'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        'recommendations': decoded['recommendations']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Error in analyzeGrowthPhoto: ${e.toString()}");
      return fallback();
    }
  }

  /// Downloads [initialPhotoUrl] and [currentPhotoUrl], sends both to Gemini
  /// for a before-vs-after treatment progress comparison, and returns a
  /// structured Map with keys:
  ///   progressScore, trend, comparisonObservation, isResolved,
  ///   adjustedRecommendation.
  Future<Map<String, dynamic>> assessTreatmentProgress({
    required String initialPhotoUrl,
    required String currentPhotoUrl,
    required String diagnosis,
    required List<String> treatmentSteps,
    required int daysSinceDiagnosis,
  }) async {
    Map<String, dynamic> fallback() => {
          'progressScore': 50,
          'trend': 'Stable',
          'comparisonObservation': 'Unable to compare photos automatically.',
          'isResolved': false,
          'adjustedRecommendation': 'Continue with the current treatment plan.',
        };

    try {
      // Download both images in parallel
      final responses = await Future.wait([
        http.get(Uri.parse(initialPhotoUrl)),
        http.get(Uri.parse(currentPhotoUrl)),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        return fallback();
      }

      final initialBytes = responses[0].bodyBytes;
      final currentBytes = responses[1].bodyBytes;

      String mimeFor(String url) {
        final u = url.toLowerCase();
        if (u.contains('.png')) return 'image/png';
        if (u.contains('.webp')) return 'image/webp';
        return 'image/jpeg';
      }

      final stepsText = treatmentSteps
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}')
          .join('\n');

      final prompt = '''
You are a plant health expert doing a treatment progress assessment.
The plant was diagnosed with "$diagnosis" $daysSinceDiagnosis days ago.
The treatment plan was:
$stepsText

I am showing you two photos. The FIRST is the initial photo when the issue was detected. The SECOND is the current photo taken today.

Please compare them carefully and respond ONLY with valid JSON containing:
- "progressScore": integer 0-100 (0 = much worse, 100 = fully recovered)
- "trend": one of "Improving", "Stable", "Worsening"
- "comparisonObservation": 2 sentences describing what changed between the two photos
- "isResolved": boolean, true if the issue appears fully healed
- "adjustedRecommendation": updated advice based on current condition (1 sentence)

Return JSON only. No markdown. No explanation.''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeFor(initialPhotoUrl), initialBytes),
          DataPart(mimeFor(currentPhotoUrl), currentBytes),
        ])
      ];

      final geminiResponse = await _model.generateContent(content).timeout(const Duration(seconds: 30));
      final raw = geminiResponse.text ?? '';

      final cleaned =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      return {
        'progressScore': (decoded['progressScore'] as num?)?.toInt() ?? 50,
        'trend': decoded['trend']?.toString() ?? 'Stable',
        'comparisonObservation':
            decoded['comparisonObservation']?.toString() ?? '',
        'isResolved': decoded['isResolved'] == true,
        'adjustedRecommendation':
            decoded['adjustedRecommendation']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("Error in assessTreatmentProgress: ${e.toString()}");
      return fallback();
    }
  }
}

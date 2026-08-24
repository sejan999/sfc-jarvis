import 'dart:convert';

import 'package:http/http.dart' as http;

import '../assistant/domain/entities/assistant_entities.dart';
import '../assistant/domain/repositories/assistant_repository.dart';

/// Performs real-time web lookups and synthesizes spoken summaries.
///
/// Strategy:
///  1. Query the DuckDuckGo Instant Answer API (keyless) for live context.
///  2. Feed the context to Gemini via [AssistantRepository.synthesizeAnswer]
///     so Jarvis produces a natural, concise spoken answer.
class WebSearchService {
  WebSearchService({required AssistantRepository repository})
      : _repository = repository;

  final AssistantRepository _repository;
  final http.Client _client = http.Client();

  /// Searches the web for [query] and returns a synthesized [SearchResult].
  Future<SearchResult> search(String query) async {
    final context = await _fetchInstantAnswer(query);
    final summary = await _repository.synthesizeAnswer(query, context);
    return SearchResult(
      query: query,
      summary: summary,
      sourceUrl: context.isEmpty ? null : 'https://duckduckgo.com/?q=$query',
    );
  }

  /// Fetches raw instant-answer JSON from DuckDuckGo.
  Future<String> _fetchInstantAnswer(String query) async {
    try {
      final uri = Uri.parse(
        'https://api.duckduckgo.com/'
        '?q=${Uri.encodeComponent(query)}&format=json&no_html=1&skip_disambig=1',
      );
      final response = await _client
          .get(uri, headers: {'User-Agent': 'SFCJarvis/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return '';

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final buffer = StringBuffer();

      final abstract = data['AbstractText'] as String?;
      if (abstract != null && abstract.isNotEmpty) {
        buffer.writeln('Abstract: $abstract');
      }

      final answer = data['Answer'] as String?;
      if (answer != null && answer.isNotEmpty && answer != 'null') {
        buffer.writeln('Direct answer: $answer');
      }

      final definition = data['Definition'] as String?;
      if (definition != null && definition.isNotEmpty) {
        buffer.writeln('Definition: $definition');
      }

      final related = data['RelatedTopics'] as List<dynamic>?;
      if (related != null && related.isNotEmpty) {
        var count = 0;
        for (final topic in related) {
          if (topic is Map<String, dynamic> && topic['Text'] != null) {
            buffer.writeln('- ${topic['Text']}');
            count++;
            if (count >= 5) break;
          }
        }
      }

      return buffer.toString().trim();
    } catch (_) {
      // Network failure is non-fatal — Gemini can still answer from
      // its own knowledge with an appropriate caveat.
      return '';
    }
  }

  void dispose() => _client.close();
}
import 'package:equatable/equatable.dart';

/// High-level intent recognized from a voice command.
enum IntentType { conversation, webSearch, deviceAction, unknown }

/// Result of parsing a raw voice command.
class ParsedCommand extends Equatable {
  const ParsedCommand({
    required this.type,
    required this.rawInput,
    this.payload = '',
  });

  final IntentType type;

  /// Original spoken text.
  final String rawInput;

  /// Extracted argument (search query, app name, phone number, etc.).
  final String payload;

  @override
  List<Object?> get props => [type, rawInput, payload];
}

/// Result of a web search operation.
class SearchResult extends Equatable {
  const SearchResult({
    required this.query,
    required this.summary,
    this.sourceUrl,
  });

  final String query;
  final String summary;
  final String? sourceUrl;

  @override
  List<Object?> get props => [query, summary, sourceUrl];
}
import '../../domain/entities/assistant_entities.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/gemini_datasource.dart';

/// Production implementation backed by the Gemini datasource.
class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(this._datasource);

  final GeminiDatasource _datasource;

  @override
  Future<String> sendMessage(String message) =>
      _datasource.sendMessage(message);

  @override
  Future<String> synthesizeAnswer(String query, String searchContext) {
    return _datasource.synthesize(
      'User query: "$query"\n\n'
      'Search context:\n$searchContext\n\n'
      'Answer the user query using this context. If the context is '
      'insufficient, answer from your own knowledge and note the limitation.',
    );
  }

  @override
  void resetConversation() => _datasource.resetSession();
}
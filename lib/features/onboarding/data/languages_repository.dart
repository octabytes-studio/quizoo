import 'package:quizoo/features/onboarding/data/languages_api.dart';
import 'package:quizoo/features/onboarding/domain/language_option.dart';

/// The only thing that talks to [LanguagesApi].
class LanguagesRepository {
  LanguagesRepository(this._api);

  final LanguagesApi _api;

  Future<List<LanguageOption>> fetchActiveLanguages() =>
      _api.fetchActiveLanguages();
}

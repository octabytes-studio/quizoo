import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/network/api_exception.dart';

part 'home_language_tabs_state.dart';

/// Owns the order of Home's language pills (plan 021).
///
/// The lead language — `ContentLanguageState.leadCode`, the language the
/// process launched with unless an explicit default change re-pinned it —
/// goes first, then every other active language in `sort_order`. Ordering is
/// business logic, so it lives here rather than in a widget's `build()`
/// (CLAUDE.md §1). The *selected* pill is not this Cubit's concern: that is
/// `ContentLanguageCubit`'s `code`, read directly by the row.
class HomeLanguageTabsCubit extends Cubit<HomeLanguageTabsState> {
  HomeLanguageTabsCubit(this._repository)
    : super(const HomeLanguageTabsLoading());

  final LanguagesRepository _repository;

  List<LanguageOption> _all = const [];
  String _leadCode = ContentLanguageRepository.fallback;

  Future<void> load({required String leadCode}) async {
    _leadCode = leadCode;
    emit(const HomeLanguageTabsLoading());
    final List<LanguageOption> languages;
    try {
      languages = await _repository.fetchActiveLanguages();
    } on ApiException catch (error) {
      if (!isClosed) emit(HomeLanguageTabsError(error));
      return;
    }
    if (isClosed) return;
    _all = languages;
    emit(HomeLanguageTabsLoaded(orderForTabs(_all, _leadCode)));
  }

  /// Re-pins [leadCode] first after an explicit default change. A no-op
  /// until the list has loaded — [load]'s own ordering picks it up then.
  void pinLead(String leadCode) {
    _leadCode = leadCode;
    if (state is HomeLanguageTabsLoaded) {
      emit(HomeLanguageTabsLoaded(orderForTabs(_all, leadCode)));
    }
  }

  /// Lead first (if present), then the rest in `sortOrder`. A lead that is
  /// not an active language leaves the list in plain `sortOrder`. Sorts a
  /// copy rather than trusting the API's own order.
  @visibleForTesting
  static List<LanguageOption> orderForTabs(
    List<LanguageOption> all,
    String leadCode,
  ) {
    final sorted = [...all]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final lead = sorted.where((language) => language.code == leadCode);
    return [
      ...lead,
      for (final language in sorted)
        if (language.code != leadCode) language,
    ];
  }
}

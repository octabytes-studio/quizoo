import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';

part 'home_state.dart';

/// Owns Home's content.
///
/// The load is deliberately two-stage, because §01's cold-open budget is a
/// two-stage paint rather than one slow one: [load] emits a [HomeLoaded] from
/// cache almost immediately (so Splash → Home stays inside 1.2 s) with
/// `isPopularRailLoading` set, then fills the rail when the network leg
/// returns. A failure on the second leg leaves Home usable and simply drops
/// the rail — the bible's "never end on a dead end" applied to a partial load.
///
/// One Cubit now serves every content language Home's pill row can switch to
/// (plan 021):
/// - **Per-language cache.** A fully loaded language is kept in memory for
///   this Cubit's lifetime (plan 021, Assumption 10), so revisiting a pill
///   emits instantly with no refetch. Errors are never cached, so a retry
///   always refetches.
/// - **Stale guard.** Only the most recently requested language may emit — a
///   slow Urdu response landing after the player has already tapped Hindi is
///   dropped.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  final Map<String, HomeContent> _cache = {};
  HomeContent? _lastShown;
  String? _requestedCode;

  bool _isStale(String code) => isClosed || _requestedCode != code;

  Future<void> load({
    required bool isSignedIn,
    required String languageCode,
  }) async {
    _requestedCode = languageCode;
    if (_cache[languageCode] case final hit?) {
      _show(HomeLoaded(languageCode: languageCode, content: hit));
      return;
    }

    final previous = _lastShown;
    emit(HomeLoading(previous: previous));
    final HomeContent cached;
    try {
      cached = await _repository.fetchCachedHome(
        isSignedIn: isSignedIn,
        languageCode: languageCode,
      );
    } on ApiException catch (error) {
      if (!_isStale(languageCode)) emit(HomeError(error, previous: previous));
      return;
    }
    if (_isStale(languageCode)) return;
    _show(
      HomeLoaded(
        languageCode: languageCode,
        content: cached,
        isPopularRailLoading: true,
      ),
    );

    HomeContent content;
    try {
      final popular = await _repository.fetchPopularRail([
        for (final subcategory in cached.subcategories) subcategory.id,
      ]);
      content = cached.copyWith(popular: popular);
    } on ApiException {
      // The rail is merchandising, not content: losing it must not take the
      // rest of Home down with it.
      content = cached;
    }
    if (_isStale(languageCode)) return;
    _cache[languageCode] = content;
    _show(HomeLoaded(languageCode: languageCode, content: content));
  }

  void _show(HomeLoaded state) {
    _lastShown = state.content;
    emit(state);
  }
}

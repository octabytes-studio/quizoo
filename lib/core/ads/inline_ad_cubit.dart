import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';

part 'inline_ad_state.dart';

/// Owns one mounted banner or native ad slot.
///
/// Lives in `core/` rather than a feature because seven features host a slot
/// (plan 022, Assumption 5). One instance per slot, created by the slot
/// widget itself, and the SDK ad is disposed with it.
class InlineAdCubit extends Cubit<InlineAdState> {
  InlineAdCubit(
    this._service, {
    double initialReservedHeight = 0,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(InlineAdLoading(reservedHeight: initialReservedHeight));

  final InlineAdService _service;
  final DateTime Function() _now;

  InlineAdRequest? _request;
  LoadedInlineAd? _ad;
  DateTime? _loadedAt;
  bool _isRefreshing = false;

  Future<void> load(InlineAdRequest request) async {
    _request = request;

    final reservedHeight = await _service.reservedHeight(request);
    if (isClosed) return;
    if (reservedHeight == null) {
      emit(const InlineAdUnavailable(reservedHeight: 0));
      return;
    }
    emit(InlineAdLoading(reservedHeight: reservedHeight));

    final ad = await _service.load(request);
    if (isClosed) {
      ad?.dispose();
      return;
    }
    if (ad == null) {
      emit(InlineAdUnavailable(reservedHeight: reservedHeight));
      return;
    }
    _show(ad);
  }

  /// Replaces a loaded ad that has outlived [adFreshnessWindow] — called when
  /// the app returns to the foreground, for slots on long-lived tabs. A
  /// failed refresh leaves the current ad where it is.
  Future<void> refreshIfStale() async {
    final request = _request;
    final loadedAt = _loadedAt;
    if (request == null || loadedAt == null || _isRefreshing) return;
    if (state is! InlineAdLoaded) return;
    if (_now().difference(loadedAt) < adFreshnessWindow) return;

    _isRefreshing = true;
    final ad = await _service.load(request);
    _isRefreshing = false;
    if (isClosed) {
      ad?.dispose();
      return;
    }
    if (ad != null) _show(ad);
  }

  void _show(LoadedInlineAd ad) {
    final previous = _ad;
    _ad = ad;
    _loadedAt = _now();
    emit(InlineAdLoaded(ad));
    previous?.dispose();
  }

  @override
  Future<void> close() {
    _ad?.dispose();
    _ad = null;
    return super.close();
  }
}

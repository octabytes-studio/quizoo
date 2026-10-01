part of 'inline_ad_cubit.dart';

/// One ad slot's states (CLAUDE.md §3).
sealed class InlineAdState extends Equatable {
  const InlineAdState();

  @override
  List<Object?> get props => const [];
}

/// The ad is being requested. [reservedHeight] is the space the slot holds
/// open meanwhile — zero until the size is known.
final class InlineAdLoading extends InlineAdState {
  const InlineAdLoading({required this.reservedHeight});

  final double reservedHeight;

  @override
  List<Object?> get props => [reservedHeight];
}

/// The ad loaded and is on screen.
final class InlineAdLoaded extends InlineAdState {
  const InlineAdLoaded(this.ad);

  final LoadedInlineAd ad;

  @override
  List<Object?> get props => [ad];
}

/// No ad — no fill, offline, or the slot could not be sized. Never an error
/// the player sees: the slot either collapses or keeps [reservedHeight] empty.
final class InlineAdUnavailable extends InlineAdState {
  const InlineAdUnavailable({required this.reservedHeight});

  final double reservedHeight;

  @override
  List<Object?> get props => [reservedHeight];
}

/// A small seam over `audioplayers` so `QuizPlayCubit` stays pure Dart and
/// testable without a plugin channel — mirrors [TtsService]'s own reasoning
/// (CLAUDE.md §11): `bloc_test` supplies a fake, the real implementation only
/// ever runs behind the widget tree.
abstract class SoundEffectsService {
  /// Starts (or restarts) the looping clock-tick, playing until [stopTicking]
  /// is called. Fired once per question, exactly when its clock starts.
  Future<void> startTicking();

  /// Stops the tick immediately — the clock ran out, was answered, or the
  /// run paused/ended.
  Future<void> stopTicking();

  /// The player answered correctly.
  Future<void> playCorrect();

  /// The player answered wrong.
  Future<void> playWrong();

  /// Fired right before the surface advances to the next question.
  Future<void> playNextQuestion();

  /// Releases every native player this service opened. Safe to call even if
  /// nothing was ever played.
  Future<void> dispose();
}

/// Which of the three onboarding cards this is.
///
/// The bible names them in order — *pick a topic*, *climb the levels*, *beat
/// your friends* — and the copy for each lives in the ARB, so this enum
/// carries only the identity and the screen resolves the words.
enum OnboardingSlideId { pick, climb, beat }

/// One card of the S-02 carousel.
///
/// No repository sits behind this: three cards of static first-run copy are
/// content the app ships with, not something it fetches, so a mock API here
/// would be theatre.
class OnboardingSlide {
  const OnboardingSlide({
    required this.id,
    required this.emoji,
    required this.gradientFrom,
    required this.gradientTo,
  });

  final OnboardingSlideId id;

  /// Fills the 190px gradient disc.
  final String emoji;

  /// Start of the disc's 150° gradient, as `#RRGGBB`.
  final String gradientFrom;

  /// End of the disc's gradient.
  final String gradientTo;

  /// The three cards, in the order the bible lists them.
  static const List<OnboardingSlide> all = [
    OnboardingSlide(
      id: OnboardingSlideId.pick,
      emoji: '🎯',
      gradientFrom: '#7B4DFF',
      gradientTo: '#2BB3FF',
    ),
    OnboardingSlide(
      id: OnboardingSlideId.climb,
      emoji: '🏆',
      gradientFrom: '#FF8A24',
      gradientTo: '#FF3D6E',
    ),
    OnboardingSlide(
      id: OnboardingSlideId.beat,
      emoji: '⚔️',
      gradientFrom: '#12C79B',
      gradientTo: '#7BE495',
    ),
  ];
}

import 'package:quizoo/core/models/badge.dart';

/// The app's fixed badge catalogue.
///
/// Lives in `core/` because two features read it independently —
/// `features/achievements` (the grid, the unlock interstitial) and
/// `features/profile` (the recent-badges rail) — which is exactly the
/// 3+-feature-reuse case that justifies `AppBadge` itself living in
/// `core/models/` (plan 003, Phase D). Names and emoji are reused directly
/// from the design bible's own worked examples rather than invented here.
abstract final class MockBadges {
  static final DateTime _unlockedRecently = DateTime(2026, 8, 22);

  static final List<AppBadge> all = [
    AppBadge(
      id: 'badge_sharpshooter',
      name: 'Sharpshooter',
      emoji: '🎯',
      description: 'Finish a level with 20/20 correct answers.',
      gradientFrom: '#FFD84D',
      gradientTo: '#F0A500',
      isLocked: false,
      rarityPercent: 4,
      unlockedAt: _unlockedRecently,
    ),
    AppBadge(
      id: 'badge_night_owl',
      name: 'Night Owl',
      emoji: '🌙',
      description: 'Play after midnight five nights in a row.',
      gradientFrom: '#7B4DFF',
      gradientTo: '#2BB3FF',
      isLocked: false,
      rarityPercent: 18,
      unlockedAt: _unlockedRecently,
    ),
    AppBadge(
      id: 'badge_quick_draw',
      name: 'Quick Draw',
      emoji: '⚡',
      description: 'Average under 3 seconds per answer in a level.',
      gradientFrom: '#12C79B',
      gradientTo: '#7BE495',
      isLocked: false,
      rarityPercent: 22,
      unlockedAt: _unlockedRecently,
    ),
    AppBadge(
      id: 'badge_week_warrior',
      name: 'Week Warrior',
      emoji: '🔥',
      description: 'Complete every daily challenge for 7 days straight.',
      gradientFrom: '#FF8A24',
      gradientTo: '#FF3D6E',
      isLocked: false,
      rarityPercent: 15,
      unlockedAt: _unlockedRecently,
    ),
    AppBadge(
      id: 'badge_big_brain',
      name: 'Big Brain',
      emoji: '🧠',
      description: 'Score 100% on ten different IQ levels.',
      gradientFrom: '#2BB3FF',
      gradientTo: '#7B4DFF',
      isLocked: false,
      rarityPercent: 9,
      unlockedAt: _unlockedRecently,
    ),
    const AppBadge(
      id: 'badge_category_king',
      name: 'Category King',
      emoji: '👑',
      description:
          'Reach Level 20 with three stars in every subcategory of a '
          'single category.',
      gradientFrom: '#7B4DFF',
      gradientTo: '#2BB3FF',
      rarityPercent: 2.1,
    ),
    const AppBadge(
      id: 'badge_centurion',
      name: 'Centurion',
      emoji: '💯',
      description: 'Answer 100 questions correctly in a row across any levels.',
      gradientFrom: '#FF8A24',
      gradientTo: '#FF3D6E',
      rarityPercent: 4.5,
    ),
    const AppBadge(
      id: 'badge_globetrotter',
      name: 'Globetrotter',
      emoji: '🌍',
      description: 'Play at least one level in every category.',
      gradientFrom: '#12C79B',
      gradientTo: '#2BB3FF',
      rarityPercent: 8,
    ),
    const AppBadge(
      id: 'badge_duelist',
      name: 'Duelist',
      emoji: '⚔️',
      description: 'Win 10 duels against other players.',
      gradientFrom: '#FF3D6E',
      gradientTo: '#7B4DFF',
      rarityPercent: 6.3,
    ),
    const AppBadge(
      id: 'badge_scholar',
      name: 'Scholar',
      emoji: '🦉',
      description: 'Reach Level 20 in five different subcategories.',
      gradientFrom: '#2BB3FF',
      gradientTo: '#12C79B',
      rarityPercent: 3.2,
    ),
    const AppBadge(
      id: 'badge_rocket',
      name: 'Rocket',
      emoji: '🚀',
      description: 'Finish a whole level averaging under 2 seconds per answer.',
      gradientFrom: '#FFC61A',
      gradientTo: '#FF8A24',
      rarityPercent: 12,
    ),
    const AppBadge(
      id: 'badge_flawless',
      name: 'Flawless',
      emoji: '💎',
      description:
          'Complete a perfect week — every daily challenge, zero wrong '
          'answers.',
      gradientFrom: '#2BB3FF',
      gradientTo: '#7B4DFF',
      rarityPercent: 1.8,
    ),
  ];

  static AppBadge byId(String id) =>
      all.firstWhere((badge) => badge.id == id, orElse: () => all.first);

  static List<AppBadge> get unlocked => [
    for (final badge in all)
      if (!badge.isLocked) badge,
  ];
}

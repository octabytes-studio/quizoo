import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/ads/ads_config.dart';
import 'package:quizoo/core/ads/ads_config_api.dart';
import 'package:quizoo/core/ads/ads_config_repository.dart';

class FakeAdsConfigApi extends Mock implements AdsConfigApi {}

void main() {
  late FakeAdsConfigApi api;
  late AdsConfigRepository repository;

  /// Stubs every key, with [ints] / [placements] / [enabled] overriding the
  /// shipping defaults.
  void stub({
    bool enabled = true,
    String placements = '',
    Map<String, int> ints = const {},
  }) {
    const defaults = {
      AdsConfigRepository.graceBreaksKey: 2,
      AdsConfigRepository.everyNBreaksKey: 2,
      AdsConfigRepository.minGapSecondsKey: 120,
      AdsConfigRepository.sessionCapKey: 8,
      AdsConfigRepository.homeFirstSectionKey: 2,
      AdsConfigRepository.homeEverySectionsKey: 5,
      AdsConfigRepository.homeMaxKey: 2,
      AdsConfigRepository.ranksAfterRowKey: 5,
    };
    when(() => api.getBool(AdsConfigRepository.enabledKey)).thenReturn(enabled);
    when(
      () => api.getString(AdsConfigRepository.disabledPlacementsKey),
    ).thenReturn(placements);
    for (final MapEntry(:key, :value) in {...defaults, ...ints}.entries) {
      when(() => api.getInt(key)).thenReturn(value);
    }
  }

  setUp(() {
    api = FakeAdsConfigApi();
    repository = AdsConfigRepository(api);
  });

  group('AdsConfigRepository', () {
    test('maps every Remote Config key onto AdsConfig', () {
      stub(
        enabled: false,
        placements: 'home_feed_native',
        ints: {
          AdsConfigRepository.graceBreaksKey: 4,
          AdsConfigRepository.everyNBreaksKey: 3,
          AdsConfigRepository.minGapSecondsKey: 90,
          AdsConfigRepository.sessionCapKey: 5,
          AdsConfigRepository.homeFirstSectionKey: 1,
          AdsConfigRepository.homeEverySectionsKey: 4,
          AdsConfigRepository.homeMaxKey: 3,
          AdsConfigRepository.ranksAfterRowKey: 7,
        },
      );

      expect(
        repository.read(),
        const AdsConfig(
          enabled: false,
          disabledPlacements: {'home_feed_native'},
          interstitialGraceBreaks: 4,
          interstitialEveryNBreaks: 3,
          interstitialMinGapSeconds: 90,
          interstitialSessionCap: 5,
          homeNativeFirstSection: 1,
          homeNativeEverySections: 4,
          homeNativeMax: 3,
          ranksNativeAfterRow: 7,
        ),
      );
    });

    test('the registered defaults read back as the shipping config', () {
      stub();

      expect(repository.read(), const AdsConfig());
    });

    test('parses the kill list, ignoring spaces and empty entries', () {
      stub(placements: ' level_map_banner, ,daily_tab_rectangle,');

      expect(repository.read().disabledPlacements, {
        'level_map_banner',
        'daily_tab_rectangle',
      });
    });

    test('clamps nonsense numbers back to their defaults', () {
      stub(
        ints: {
          AdsConfigRepository.graceBreaksKey: -1,
          AdsConfigRepository.everyNBreaksKey: 0,
          AdsConfigRepository.minGapSecondsKey: -30,
          AdsConfigRepository.sessionCapKey: -2,
          AdsConfigRepository.homeEverySectionsKey: 0,
          AdsConfigRepository.homeMaxKey: -5,
        },
      );

      expect(repository.read(), const AdsConfig());
    });

    test('zero is a legitimate value where it means "none"', () {
      stub(
        ints: {
          AdsConfigRepository.graceBreaksKey: 0,
          AdsConfigRepository.sessionCapKey: 0,
          AdsConfigRepository.homeMaxKey: 0,
        },
      );

      final config = repository.read();
      expect(config.interstitialGraceBreaks, 0);
      expect(config.interstitialSessionCap, 0);
      expect(config.homeNativeMax, 0);
    });

    test('returns the defaults when Remote Config cannot be read', () {
      when(() => api.getBool(any())).thenThrow(StateError('not initialised'));

      expect(repository.read(), const AdsConfig());
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/presentation/bloc/home_language_tabs_cubit.dart';

class _MockLanguagesRepository extends Mock implements LanguagesRepository {}

const _en = LanguageOption(
  code: 'en',
  name: 'English',
  nativeName: 'English',
  isRtl: false,
  sortOrder: 1,
);
const _ur = LanguageOption(
  code: 'ur',
  name: 'Urdu',
  nativeName: 'اردو',
  isRtl: true,
  sortOrder: 2,
);
const _hi = LanguageOption(
  code: 'hi',
  name: 'Hindi',
  nativeName: 'हिन्दी',
  isRtl: false,
  sortOrder: 3,
);

void main() {
  late _MockLanguagesRepository repository;

  setUp(() => repository = _MockLanguagesRepository());

  void stubLanguages() => when(
    () => repository.fetchActiveLanguages(),
  ).thenAnswer((_) async => const [_en, _ur, _hi]);

  group('HomeLanguageTabsCubit', () {
    test('starts loading', () {
      expect(
        HomeLanguageTabsCubit(repository).state,
        const HomeLanguageTabsLoading(),
      );
    });

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'success path: the lead goes first, then the rest in sort order',
      setUp: stubLanguages,
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) => cubit.load(leadCode: 'hi'),
      expect: () => [
        const HomeLanguageTabsLoading(),
        const HomeLanguageTabsLoaded([_hi, _en, _ur]),
      ],
    );

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'failure path: a failed fetch emits an error',
      setUp: () => when(
        () => repository.fetchActiveLanguages(),
      ).thenAnswer((_) async => throw const ApiException.network()),
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) => cubit.load(leadCode: 'en'),
      expect: () => [
        const HomeLanguageTabsLoading(),
        isA<HomeLanguageTabsError>(),
      ],
    );

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'pinLead after a load reorders around the new lead',
      setUp: stubLanguages,
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) async {
        await cubit.load(leadCode: 'en');
        cubit.pinLead('ur');
      },
      expect: () => [
        const HomeLanguageTabsLoading(),
        const HomeLanguageTabsLoaded([_en, _ur, _hi]),
        const HomeLanguageTabsLoaded([_ur, _en, _hi]),
      ],
    );

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'pinLead while loading emits nothing',
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) => cubit.pinLead('ur'),
      expect: () => const <HomeLanguageTabsState>[],
    );

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'pinLead after an error emits nothing',
      setUp: () => when(
        () => repository.fetchActiveLanguages(),
      ).thenAnswer((_) async => throw const ApiException.network()),
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) async {
        await cubit.load(leadCode: 'en');
        cubit.pinLead('ur');
      },
      expect: () => [
        const HomeLanguageTabsLoading(),
        isA<HomeLanguageTabsError>(),
      ],
    );

    blocTest<HomeLanguageTabsCubit, HomeLanguageTabsState>(
      'a pinLead that lands before the list honours it once loaded',
      setUp: stubLanguages,
      build: () => HomeLanguageTabsCubit(repository),
      act: (cubit) async {
        final load = cubit.load(leadCode: 'en');
        cubit.pinLead('hi');
        await load;
      },
      expect: () => [
        const HomeLanguageTabsLoading(),
        const HomeLanguageTabsLoaded([_hi, _en, _ur]),
      ],
    );
  });

  group('HomeLanguageTabsCubit.orderForTabs', () {
    test('a lead missing from the list leaves plain sort order', () {
      expect(HomeLanguageTabsCubit.orderForTabs(const [_en, _ur, _hi], 'fr'), [
        _en,
        _ur,
        _hi,
      ]);
    });

    test('sorts an out-of-order input rather than trusting the API', () {
      expect(HomeLanguageTabsCubit.orderForTabs(const [_hi, _en, _ur], 'ur'), [
        _ur,
        _en,
        _hi,
      ]);
    });
  });
}

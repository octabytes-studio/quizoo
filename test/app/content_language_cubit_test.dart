import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';

class _MockContentLanguageRepository extends Mock
    implements ContentLanguageRepository {}

void main() {
  late _MockContentLanguageRepository repository;

  setUp(() {
    repository = _MockContentLanguageRepository();
    when(() => repository.current).thenReturn('en');
  });

  group('ContentLanguageCubit', () {
    test('starts from the repository\'s cached value', () {
      when(() => repository.current).thenReturn('ur');
      expect(
        ContentLanguageCubit(repository).state,
        const ContentLanguageLoaded('ur'),
      );
    });

    blocTest<ContentLanguageCubit, ContentLanguageState>(
      'select emits the new code and persists it',
      setUp: () =>
          when(() => repository.select(any())).thenAnswer((_) async {}),
      build: () => ContentLanguageCubit(repository),
      act: (cubit) => cubit.select('ur'),
      expect: () => [const ContentLanguageLoaded('ur')],
      verify: (_) => verify(() => repository.select('ur')).called(1),
    );

    blocTest<ContentLanguageCubit, ContentLanguageState>(
      'selecting the current code again emits nothing and does not persist',
      build: () => ContentLanguageCubit(repository),
      act: (cubit) => cubit.select('en'),
      expect: () => const <ContentLanguageState>[],
      verify: (_) => verifyNever(() => repository.select(any())),
    );

    blocTest<ContentLanguageCubit, ContentLanguageState>(
      'adoptFromBackend emits the backend value when it differs',
      setUp: () => when(
        () => repository.reconcileWithBackend(),
      ).thenAnswer((_) async => 'ur'),
      build: () => ContentLanguageCubit(repository),
      act: (cubit) => cubit.adoptFromBackend(),
      expect: () => [const ContentLanguageLoaded('ur')],
    );

    group('lead language (plan 021)', () {
      setUp(
        () => when(() => repository.select(any())).thenAnswer((_) async {}),
      );

      test('starts with the lead pinned to the launch default', () {
        final state = ContentLanguageCubit(repository).state;
        expect(state.code, 'en');
        expect(state.leadCode, 'en');
      });

      blocTest<ContentLanguageCubit, ContentLanguageState>(
        'switchTo persists the new code but leaves the lead alone',
        build: () => ContentLanguageCubit(repository),
        act: (cubit) => cubit.switchTo('ur'),
        expect: () => [const ContentLanguageLoaded('ur', leadCode: 'en')],
        verify: (_) => verify(() => repository.select('ur')).called(1),
      );

      blocTest<ContentLanguageCubit, ContentLanguageState>(
        'switchTo the current code emits nothing and does not persist',
        build: () => ContentLanguageCubit(repository),
        act: (cubit) => cubit.switchTo('en'),
        expect: () => const <ContentLanguageState>[],
        verify: (_) => verifyNever(() => repository.select(any())),
      );

      blocTest<ContentLanguageCubit, ContentLanguageState>(
        'select after switchTo re-pins the lead',
        build: () => ContentLanguageCubit(repository),
        act: (cubit) async {
          await cubit.switchTo('hi');
          await cubit.select('ur');
        },
        expect: () => [
          const ContentLanguageLoaded('hi', leadCode: 'en'),
          const ContentLanguageLoaded('ur'),
        ],
      );

      blocTest<ContentLanguageCubit, ContentLanguageState>(
        'selecting the current code while the lead differs re-pins it',
        build: () => ContentLanguageCubit(repository),
        seed: () => const ContentLanguageLoaded('hi', leadCode: 'en'),
        act: (cubit) => cubit.select('hi'),
        expect: () => [const ContentLanguageLoaded('hi')],
      );

      blocTest<ContentLanguageCubit, ContentLanguageState>(
        'adoptFromBackend pins the backend value as the lead',
        setUp: () => when(
          () => repository.reconcileWithBackend(),
        ).thenAnswer((_) async => 'ur'),
        build: () => ContentLanguageCubit(repository),
        seed: () => const ContentLanguageLoaded('hi', leadCode: 'en'),
        act: (cubit) => cubit.adoptFromBackend(),
        expect: () => [
          isA<ContentLanguageLoaded>()
              .having((s) => s.code, 'code', 'ur')
              .having((s) => s.leadCode, 'leadCode', 'ur'),
        ],
      );

      test('the next launch leads with the last-switched language', () async {
        var persisted = 'en';
        when(() => repository.current).thenAnswer((_) => persisted);
        when(() => repository.select(any())).thenAnswer((invocation) async {
          persisted = invocation.positionalArguments.single as String;
        });

        final firstLaunch = ContentLanguageCubit(repository);
        await firstLaunch.switchTo('ur');
        expect(firstLaunch.state.leadCode, 'en');
        await firstLaunch.close();

        final nextLaunch = ContentLanguageCubit(repository);
        expect(nextLaunch.state, const ContentLanguageLoaded('ur'));
        expect(nextLaunch.state.leadCode, 'ur');
      });
    });

    blocTest<ContentLanguageCubit, ContentLanguageState>(
      'adoptFromBackend emits nothing when the backend has nothing new',
      setUp: () => when(
        () => repository.reconcileWithBackend(),
      ).thenAnswer((_) async => null),
      build: () => ContentLanguageCubit(repository),
      act: (cubit) => cubit.adoptFromBackend(),
      expect: () => const <ContentLanguageState>[],
    );
  });
}

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

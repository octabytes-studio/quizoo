import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/onboarding/data/languages_repository.dart';
import 'package:quizoo/features/onboarding/domain/language_option.dart';
import 'package:quizoo/features/onboarding/presentation/bloc/language_picker_cubit.dart';

class _MockLanguagesRepository extends Mock implements LanguagesRepository {}

void main() {
  late _MockLanguagesRepository repository;

  const languages = [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      isRtl: false,
      sortOrder: 1,
    ),
    LanguageOption(
      code: 'ur',
      name: 'Urdu',
      nativeName: 'اردو',
      isRtl: true,
      sortOrder: 2,
    ),
  ];

  setUp(() => repository = _MockLanguagesRepository());

  group('LanguagePickerCubit', () {
    test('starts in its initial state', () {
      expect(
        LanguagePickerCubit(repository).state,
        isA<LanguagePickerLoading>(),
      );
    });

    blocTest<LanguagePickerCubit, LanguagePickerState>(
      'success path: loads the active languages',
      setUp: () {
        when(
          () => repository.fetchActiveLanguages(),
        ).thenAnswer((_) async => languages);
      },
      build: () => LanguagePickerCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<LanguagePickerLoading>(),
        isA<LanguagePickerLoaded>().having(
          (state) => state.languages,
          'languages',
          languages,
        ),
      ],
    );

    blocTest<LanguagePickerCubit, LanguagePickerState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchActiveLanguages(),
        ).thenThrow(const ApiException.network());
      },
      build: () => LanguagePickerCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<LanguagePickerLoading>(), isA<LanguagePickerError>()],
    );

    blocTest<LanguagePickerCubit, LanguagePickerState>(
      'load() can be retried after a failure',
      setUp: () {
        when(
          () => repository.fetchActiveLanguages(),
        ).thenThrow(const ApiException.network());
      },
      build: () => LanguagePickerCubit(repository),
      act: (cubit) async {
        await cubit.load();
        when(
          () => repository.fetchActiveLanguages(),
        ).thenAnswer((_) async => languages);
        await cubit.load();
      },
      expect: () => [
        isA<LanguagePickerLoading>(),
        isA<LanguagePickerError>(),
        isA<LanguagePickerLoading>(),
        isA<LanguagePickerLoaded>(),
      ],
    );
  });
}

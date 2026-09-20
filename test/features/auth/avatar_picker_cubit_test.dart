import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/avatars_repository.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';
import 'package:quizoo/features/auth/presentation/bloc/avatar_picker_cubit.dart';

class _MockAvatarsRepository extends Mock implements AvatarsRepository {}

void main() {
  late _MockAvatarsRepository repository;

  const avatars = [
    AvatarOption(id: '1', emoji: '🐼', sortOrder: 1),
    AvatarOption(id: '2', emoji: '🦊', sortOrder: 2),
  ];

  setUp(() => repository = _MockAvatarsRepository());

  group('AvatarPickerCubit', () {
    test('starts in its initial state', () {
      expect(AvatarPickerCubit(repository).state, isA<AvatarPickerLoading>());
    });

    blocTest<AvatarPickerCubit, AvatarPickerState>(
      'success path: loads the active avatars',
      setUp: () {
        when(
          () => repository.fetchActiveAvatars(),
        ).thenAnswer((_) async => avatars);
      },
      build: () => AvatarPickerCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AvatarPickerLoading>(),
        isA<AvatarPickerLoaded>().having(
          (state) => state.avatars,
          'avatars',
          avatars,
        ),
      ],
    );

    blocTest<AvatarPickerCubit, AvatarPickerState>(
      'failure path: a failed fetch surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchActiveAvatars(),
        ).thenThrow(const ApiException.network());
      },
      build: () => AvatarPickerCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<AvatarPickerLoading>(), isA<AvatarPickerError>()],
    );
  });
}

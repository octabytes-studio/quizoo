import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/data/catalog_api.dart';
import 'package:quizoo/features/catalog/data/catalog_repository.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:quizoo/features/catalog/presentation/bloc/category_detail_cubit.dart';
import 'package:quizoo/features/catalog/presentation/bloc/level_map_cubit.dart';

class _MockCatalogApi extends Mock implements CatalogApi {}

class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  final football = MockCatalog.subcategoryById(MockCatalog.footballId);
  final sports = MockCatalog.categoryById(MockCatalog.sportsId);

  final sportsTopics = MockCatalog.forCategory(MockCatalog.sportsId);
  final detail = CategoryDetail(
    category: sports,
    topics: sportsTopics,
    playerCount: 128000,
    starsEarned: 86,
    levelsCleared: 33,
    resumeTopic: CatalogApi.resumeTopic(sportsTopics),
  );

  final map = LevelMap(
    category: sports,
    subcategory: football,
    levels: MockCatalog.levelsFor(football),
    rank: 412,
  );

  group('CategoryDetailCubit', () {
    late _MockCatalogRepository repository;

    setUp(() => repository = _MockCatalogRepository());

    test('starts in its initial state', () {
      expect(
        CategoryDetailCubit(repository).state,
        isA<CategoryDetailInitial>(),
      );
    });

    blocTest<CategoryDetailCubit, CategoryDetailState>(
      'success path: loads a category and its topics',
      setUp: () {
        when(
          () => repository.fetchCategory(any(), locale: any(named: 'locale')),
        ).thenAnswer((_) async => detail);
      },
      build: () => CategoryDetailCubit(repository),
      act: (cubit) => cubit.load(MockCatalog.sportsId, locale: 'en'),
      expect: () => [
        isA<CategoryDetailLoading>(),
        isA<CategoryDetailLoaded>()
            .having((state) => state.detail.topics, 'topics', isNotEmpty)
            .having((state) => state.sort, 'sort', TopicSort.popular)
            .having(
              (state) => state.detail.resumeTopic?.id,
              'resumeTopic',
              'sub_cricket',
            ),
      ],
    );

    blocTest<CategoryDetailCubit, CategoryDetailState>(
      'failure path: a missing category surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchCategory(any(), locale: any(named: 'locale')),
        ).thenThrow(
          const ApiException(
            'No such category',
            kind: ApiErrorKind.notFound,
            code: 'ERR_CONTENT_404',
          ),
        );
      },
      build: () => CategoryDetailCubit(repository),
      act: (cubit) => cubit.load('nope', locale: 'en'),
      expect: () => [
        isA<CategoryDetailLoading>(),
        isA<CategoryDetailError>().having(
          (state) => state.error.code,
          'code',
          'ERR_CONTENT_404',
        ),
      ],
    );
  });

  group('LevelMapCubit', () {
    late _MockCatalogRepository repository;

    setUp(() => repository = _MockCatalogRepository());

    test('starts in its initial state', () {
      expect(LevelMapCubit(repository).state, isA<LevelMapInitial>());
    });

    blocTest<LevelMapCubit, LevelMapState>(
      'success path: loads thirty levels with one marked current',
      setUp: () {
        when(
          () => repository.fetchLevelMap(
            categoryId: any(named: 'categoryId'),
            subcategoryId: any(named: 'subcategoryId'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer((_) async => map);
      },
      build: () => LevelMapCubit(repository),
      act: (cubit) => cubit.load(
        categoryId: MockCatalog.sportsId,
        subcategoryId: MockCatalog.footballId,
        locale: 'en',
      ),
      expect: () => [
        isA<LevelMapLoading>(),
        isA<LevelMapLoaded>()
            .having((state) => state.map.levels, 'levels', hasLength(30))
            .having(
              (state) => state.map.currentLevel.number,
              'current',
              MockCatalog.signedInLevelsCleared + 1,
            ),
      ],
    );

    blocTest<LevelMapCubit, LevelMapState>(
      'a topic with no levels is an empty state, not an error',
      setUp: () {
        when(
          () => repository.fetchLevelMap(
            categoryId: any(named: 'categoryId'),
            subcategoryId: any(named: 'subcategoryId'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer((_) async => map.copyWith(levels: const []));
      },
      build: () => LevelMapCubit(repository),
      act: (cubit) => cubit.load(
        categoryId: MockCatalog.sportsId,
        subcategoryId: MockCatalog.footballId,
        locale: 'en',
      ),
      expect: () => [isA<LevelMapLoading>(), isA<LevelMapEmpty>()],
    );

    blocTest<LevelMapCubit, LevelMapState>(
      'failure path: a failed load surfaces as an error',
      setUp: () {
        when(
          () => repository.fetchLevelMap(
            categoryId: any(named: 'categoryId'),
            subcategoryId: any(named: 'subcategoryId'),
            locale: any(named: 'locale'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => LevelMapCubit(repository),
      act: (cubit) => cubit.load(
        categoryId: MockCatalog.sportsId,
        subcategoryId: MockCatalog.footballId,
        locale: 'en',
      ),
      expect: () => [isA<LevelMapLoading>(), isA<LevelMapError>()],
    );
  });

  group('CatalogRepository', () {
    late _MockCatalogApi api;
    late CatalogRepository repository;

    setUp(() {
      api = _MockCatalogApi();
      repository = CatalogRepository(api);
    });

    test('success path: passes the API response through', () async {
      when(
        () => api.fetchCategory(any(), locale: any(named: 'locale')),
      ).thenAnswer((_) async => detail);
      expect(
        (await repository.fetchCategory(
          MockCatalog.sportsId,
          locale: 'en',
        )).topics,
        isNotEmpty,
      );
    });

    test('error-mapping path: the typed exception reaches the caller', () {
      when(
        () => api.fetchCategory(any(), locale: any(named: 'locale')),
      ).thenThrow(const ApiException.network());
      expect(
        () => repository.fetchCategory(MockCatalog.sportsId, locale: 'en'),
        throwsA(isA<ApiException>()),
      );
    });

    test('sorting reorders topics without losing any', () {
      final byName = CatalogRepository.sorted(detail, TopicSort.alphabetical);
      expect(byName.topics, hasLength(detail.topics.length));
      expect(byName.topics.first.name, 'Basketball');

      final byProgress = CatalogRepository.sorted(detail, TopicSort.progress);
      expect(byProgress.topics.first.levelsCleared, 20);
    });
  });

  group('CatalogApi.resumeTopic', () {
    test('the topic with the most levels cleared wins', () {
      // Cricket (20 cleared) outranks Football (11) and Hockey (2).
      expect(CatalogApi.resumeTopic(sportsTopics)?.id, 'sub_cricket');
    });

    test('no started topic yields a null resume topic', () {
      final untouched = MockCatalog.asGuest(sportsTopics);
      expect(CatalogApi.resumeTopic(untouched), isNull);
    });
  });

  group('MockCatalog level generation', () {
    test('follows the 30-level, 3-tier ladder: bands, clocks, question '
        'counts and every tenth level a boss', () {
      final levels = MockCatalog.levelsFor(football);

      expect(levels, hasLength(30));
      expect(levels[0].difficultyBand, DifficultyBand.warmUp);
      expect(levels[0].secondsPerQuestion, 20);
      expect(levels[0].questionCount, 10);
      expect(levels[15].difficultyBand, DifficultyBand.steady);
      expect(levels[15].secondsPerQuestion, 15);
      expect(levels[15].questionCount, 15);
      expect(levels[25].difficultyBand, DifficultyBand.sharp);
      expect(levels[25].secondsPerQuestion, 10);
      expect(levels[25].questionCount, 20);

      expect(
        levels.where((level) => level.isBoss).map((level) => level.number),
        [10, 20, 30],
      );

      // Exactly one node is "you are here".
      expect(
        levels.where((level) => level.status == LevelStatus.current),
        hasLength(1),
      );
    });

    test('a level id round-trips through its parser', () {
      final id = MockCatalog.levelId(MockCatalog.footballId, 12);
      expect(MockCatalog.parseLevelId(id), (MockCatalog.footballId, 12));
    });
  });
}

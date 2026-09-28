import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/models/category.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
import 'package:quizoo/features/home/domain/search_result.dart';
import 'package:quizoo/features/home/presentation/bloc/home_cubit.dart';
import 'package:quizoo/features/home/presentation/bloc/search_cubit.dart';

class _MockHomeApi extends Mock implements HomeApi {}

class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  group('HomeCubit', () {
    late _MockHomeRepository repository;

    const cached = HomeContent(categories: MockCatalog.categories);
    const popular = [
      PopularQuiz(
        id: 'pq',
        subcategoryId: MockCatalog.footballId,
        title: 'Football Legends',
        emoji: '⚽',
        colorFrom: '#FF8A24',
        colorTo: '#FF3D6E',
      ),
    ];

    setUp(() => repository = _MockHomeRepository());

    test('starts in its initial state', () {
      expect(HomeCubit(repository).state, isA<HomeInitial>());
    });

    blocTest<HomeCubit, HomeState>(
      'success path: paints from cache first, then fills the popular rail',
      setUp: () {
        when(
          () => repository.fetchCachedHome(
            isSignedIn: any(named: 'isSignedIn'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => cached);
        when(
          () => repository.fetchPopularRail(any()),
        ).thenAnswer((_) async => popular);
      },
      build: () => HomeCubit(repository),
      act: (cubit) => cubit.load(isSignedIn: false, languageCode: 'en'),
      expect: () => [
        isA<HomeLoading>(),
        // §01's two-stage paint: Home is already usable while the rail loads.
        isA<HomeLoaded>()
            .having(
              (state) => state.isPopularRailLoading,
              'railLoading',
              isTrue,
            )
            .having((state) => state.content.popular, 'popular', isEmpty),
        isA<HomeLoaded>()
            .having(
              (state) => state.isPopularRailLoading,
              'railLoading',
              isFalse,
            )
            .having((state) => state.content.popular, 'popular', hasLength(1)),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'failure path: a failed cached read is the only way Home has nothing',
      setUp: () {
        when(
          () => repository.fetchCachedHome(
            isSignedIn: any(named: 'isSignedIn'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => HomeCubit(repository),
      act: (cubit) => cubit.load(isSignedIn: false, languageCode: 'en'),
      expect: () => [isA<HomeLoading>(), isA<HomeError>()],
    );

    blocTest<HomeCubit, HomeState>(
      'losing the popular rail leaves the rest of Home intact',
      setUp: () {
        when(
          () => repository.fetchCachedHome(
            isSignedIn: any(named: 'isSignedIn'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => cached);
        when(
          () => repository.fetchPopularRail(any()),
        ).thenThrow(const ApiException.network());
      },
      build: () => HomeCubit(repository),
      act: (cubit) => cubit.load(isSignedIn: false, languageCode: 'en'),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
        isA<HomeLoaded>()
            .having(
              (state) => state.isPopularRailLoading,
              'railLoading',
              isFalse,
            )
            .having(
              (state) => state.content.categories,
              'categories',
              isNotEmpty,
            ),
      ],
    );
  });

  group('HomeContent.sections', () {
    // Pure and Cubit-free (plan 009): every category in the fixture has at
    // least one topic, so a plain load groups and orders without promotion.
    test('groups by category and orders by Category.order', () {
      const content = HomeContent(
        categories: MockCatalog.categories,
        subcategories: MockCatalog.subcategories,
      );

      final sections = content.sections;

      expect(sections, hasLength(MockCatalog.categories.length));
      expect(
        sections.map((section) => section.category.id),
        MockCatalog.categories.map((category) => category.id),
      );
      expect(
        sections.first.topics,
        MockCatalog.forCategory(MockCatalog.sportsId),
      );
    });

    test('drops a category with no topics rather than an empty rail', () {
      const emptyCategory = Category(
        id: 'cat_empty',
        name: 'Empty',
        emoji: '🕳️',
        colorFrom: '#000000',
        colorTo: '#000000',
        order: -1,
      );
      final content = HomeContent(
        categories: [emptyCategory, ...MockCatalog.categories],
        subcategories: MockCatalog.subcategories,
      );

      expect(
        content.sections.map((section) => section.category.id),
        isNot(contains('cat_empty')),
      );
    });

    test('promotes the continue entry\'s own category to first', () {
      // Science (order 1) would otherwise sort after Sports (order 0).
      final content = HomeContent(
        categories: MockCatalog.categories,
        subcategories: MockCatalog.subcategories,
        continueEntry: const ContinueEntry(
          subcategoryId: MockCatalog.solarSystemId,
          subcategoryName: 'Solar System',
          emoji: '🪐',
          plateColor: '#DDF1FF',
          levelNumber: 4,
        ),
      );

      expect(content.sections.first.category.id, MockCatalog.scienceId);
      // Everything else still follows Category.order.
      expect(content.sections[1].category.id, MockCatalog.sportsId);
    });
  });

  group('SearchCubit', () {
    late _MockHomeRepository repository;

    setUp(() => repository = _MockHomeRepository());

    test('starts with nothing typed', () {
      expect(
        SearchCubit(repository, languageCode: 'en').state,
        isA<SearchInitial>(),
      );
    });

    blocTest<SearchCubit, SearchState>(
      'success path: a query resolves to results after the debounce',
      setUp: () {
        when(
          () => repository.search(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async {
          final subcategory = MockCatalog.subcategoryById(
            MockCatalog.footballId,
          );
          return [
            SearchResult(
              subcategory: subcategory,
              categoryName: MockCatalog.categoryById(
                subcategory.categoryId,
              ).name,
            ),
          ];
        });
      },
      build: () => SearchCubit(repository, languageCode: 'en'),
      act: (cubit) => cubit.searchNow('foot'),
      expect: () => [
        isA<SearchSearching>(),
        isA<SearchSuccess>()
            .having((state) => state.results, 'results', hasLength(1))
            .having((state) => state.isEmpty, 'isEmpty', isFalse),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'no matches is an empty state, not a failure',
      setUp: () {
        when(
          () => repository.search(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer((_) async => []);
      },
      build: () => SearchCubit(repository, languageCode: 'en'),
      act: (cubit) => cubit.searchNow('zzzz'),
      expect: () => [
        isA<SearchSearching>(),
        isA<SearchSuccess>().having(
          (state) => state.isEmpty,
          'isEmpty',
          isTrue,
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'failure path: a failed lookup surfaces as an error',
      setUp: () {
        when(
          () => repository.search(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => SearchCubit(repository, languageCode: 'en'),
      act: (cubit) => cubit.searchNow('foot'),
      expect: () => [isA<SearchSearching>(), isA<SearchFailure>()],
    );

    blocTest<SearchCubit, SearchState>(
      'clearing the field returns to the trending cloud',
      build: () => SearchCubit(repository, languageCode: 'en'),
      act: (cubit) => cubit.queryChanged('   '),
      expect: () => [isA<SearchInitial>()],
    );
  });

  group('HomeRepository', () {
    late _MockHomeApi api;
    late HomeRepository repository;

    setUp(() {
      api = _MockHomeApi();
      repository = HomeRepository(api);
    });

    test('search matches a topic by name, sub-path or category', () async {
      when(
        () => api.fetchCachedHome(
          isSignedIn: any(named: 'isSignedIn'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => const HomeContent(
          categories: MockCatalog.categories,
          subcategories: MockCatalog.subcategories,
        ),
      );

      // By its own name.
      expect(
        await repository.search('football', languageCode: 'en'),
        hasLength(1),
      );
      // By the sub-path the breadcrumb prints — "Science › Astronomy".
      final byPath = await repository.search('astronomy', languageCode: 'en');
      expect(byPath, isNotEmpty);
      expect(
        byPath.every((result) => result.subcategory.groupName == 'Astronomy'),
        isTrue,
      );
      // By parent category.
      expect(await repository.search('sports', languageCode: 'en'), isNotEmpty);
      // An empty query never searches at all.
      expect(await repository.search('  ', languageCode: 'en'), isEmpty);
    });

    test('fetchCachedHome passes a signed-in profile row\'s streak_days/'
        'player_level straight through as HomeContent.dayStreak/playerLevel '
        '(plan 019)', () async {
      when(
        () => api.fetchCachedHome(
          isSignedIn: any(named: 'isSignedIn'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => const HomeContent(dayStreak: 7, playerLevel: 9),
      );

      final content = await repository.fetchCachedHome(
        isSignedIn: true,
        languageCode: 'en',
      );

      expect(content.dayStreak, 7);
      expect(content.playerLevel, 9);
    });

    test('error-mapping path: the API exception reaches the caller', () async {
      when(
        () => api.fetchCachedHome(
          isSignedIn: any(named: 'isSignedIn'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenThrow(const ApiException.network());

      expect(
        () => repository.fetchCachedHome(isSignedIn: false, languageCode: 'en'),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => repository.search('foot', languageCode: 'en'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

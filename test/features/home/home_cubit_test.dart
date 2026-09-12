import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/data/home_api.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';
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
          () => repository.fetchPopularRail(),
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
          () => repository.fetchPopularRail(),
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

    blocTest<HomeCubit, HomeState>(
      'the category filter narrows the grid, and re-tapping clears it',
      setUp: () {
        when(
          () => repository.fetchCachedHome(
            isSignedIn: any(named: 'isSignedIn'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer(
          (_) async => const HomeContent(
            categories: MockCatalog.categories,
            subcategories: MockCatalog.subcategories,
          ),
        );
        when(() => repository.fetchPopularRail()).thenAnswer((_) async => []);
      },
      build: () => HomeCubit(repository),
      act: (cubit) async {
        await cubit.load(isSignedIn: false, languageCode: 'en');
        cubit.selectCategory(MockCatalog.sportsId);

        final filtered = cubit.state as HomeLoaded;
        expect(filtered.selectedCategoryId, MockCatalog.sportsId);
        expect(
          filtered.visibleSubcategories.every(
            (topic) => topic.categoryId == MockCatalog.sportsId,
          ),
          isTrue,
        );

        // Tapping the active chip again clears the filter, exactly as the
        // "✨ All" chip does.
        cubit.selectCategory(MockCatalog.sportsId);
      },
      verify: (cubit) {
        final cleared = cubit.state as HomeLoaded;
        expect(cleared.selectedCategoryId, isNull);
        expect(
          cleared.visibleSubcategories.length,
          MockCatalog.subcategories.length,
        );
      },
    );
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
        ).thenAnswer(
          (_) async => [MockCatalog.subcategoryById(MockCatalog.footballId)],
        );
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
      expect(byPath.every((topic) => topic.groupName == 'Astronomy'), isTrue);
      // By parent category.
      expect(await repository.search('sports', languageCode: 'en'), isNotEmpty);
      // An empty query never searches at all.
      expect(await repository.search('  ', languageCode: 'en'), isEmpty);
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

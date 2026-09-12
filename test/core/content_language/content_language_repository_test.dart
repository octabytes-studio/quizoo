import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/content_language/content_language_api.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockContentLanguageApi extends Mock implements ContentLanguageApi {}

void main() {
  late _MockContentLanguageApi api;
  late ContentLanguageRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = _MockContentLanguageApi();
    repository = ContentLanguageRepository(
      api,
      await SharedPreferences.getInstance(),
    );
  });

  group('ContentLanguageRepository', () {
    test('current defaults to \'en\' with nothing cached', () {
      expect(repository.current, 'en');
    });

    test('select persists locally and calls the API', () async {
      when(() => api.updateProfileLocale('ur')).thenAnswer((_) async {});

      await repository.select('ur');

      expect(repository.current, 'ur');
      verify(() => api.updateProfileLocale('ur')).called(1);
    });

    test('select does not throw even when the API throws', () async {
      // `thenAnswer` (not `thenThrow`) so the error arrives via the returned
      // Future, matching how a real `async` implementation would actually
      // fail — `thenThrow` makes a mocked method throw synchronously at the
      // call site instead, which `select`'s `.catchError` is never meant to
      // guard against.
      when(
        () => api.updateProfileLocale('ur'),
      ).thenAnswer((_) async => throw const ApiException.network());

      await expectLater(repository.select('ur'), completes);
      expect(repository.current, 'ur');
    });

    test('reconcileWithBackend adopts a differing backend value', () async {
      when(() => api.fetchProfileLocale()).thenAnswer((_) async => 'ur');

      final result = await repository.reconcileWithBackend();

      expect(result, 'ur');
      expect(repository.current, 'ur');
    });

    test('reconcileWithBackend returns null and leaves current unchanged '
        'when the backend agrees', () async {
      when(() => api.fetchProfileLocale()).thenAnswer((_) async => 'en');

      final result = await repository.reconcileWithBackend();

      expect(result, isNull);
      expect(repository.current, 'en');
    });

    test('reconcileWithBackend returns null and leaves current unchanged '
        'when the backend has nothing', () async {
      when(() => api.fetchProfileLocale()).thenAnswer((_) async => null);

      final result = await repository.reconcileWithBackend();

      expect(result, isNull);
      expect(repository.current, 'en');
    });

    test('reconcileWithBackend returns null and leaves current unchanged '
        'when the API throws', () async {
      when(
        () => api.fetchProfileLocale(),
      ).thenThrow(const ApiException.network());

      final result = await repository.reconcileWithBackend();

      expect(result, isNull);
      expect(repository.current, 'en');
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Runs once per test file (package:test's convention), before that file's
/// own `main()`.
///
/// A handful of screens (`HomeScreen`, `DeleteAccountScreen`,
/// `QuizResultScreen`, ...) construct their own real `*Api(supabase)`
/// inline, reaching `Supabase.instance.client` directly — a pattern that
/// works everywhere else because CLAUDE.md §11's tests mock the `*_api.dart`
/// boundary instead of touching Supabase at all. The few widget tests that
/// pump one of those screens whole still need *some* initialized client so
/// construction does not throw "not initialized"; this points it at an
/// address that resolves to nothing, so any query it attempts fails fast and
/// surfaces as a handled `ApiException` — the same failure-path UI those
/// tests already know how to assert on. No test in this suite hits a real
/// Supabase project (plan 005's Testing strategy) — this is a deliberately
/// unreachable placeholder, not a project's real URL.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Registered rather than awaited directly here: constructing the client's
  // underlying `HttpClient` touches flutter_test's `HttpOverrides`, which
  // needs to run inside a live test zone — one only exists once the runner
  // has actually entered a test/setUpAll callback, not during this
  // file-level bootstrap.
  setUpAll(() async {
    // Supabase.initialize's session-persistence layer reads through
    // shared_preferences on construction, which needs a mock method-channel
    // backend primed before it asks.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.invalid',
      publishableKey: 'test-anon-key',
    );
  });
  await testMain();
}

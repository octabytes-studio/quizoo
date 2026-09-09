import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ready [SharedPreferences] instance backing `QuizooApp`'s
/// `OnboardingRepository`/`AuthRepository` in a test — nothing is persisted
/// beyond the current test's in-memory mock store.
Future<SharedPreferences> testPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

/// Pumps [child] inside the same theme, sizing and localization scaffolding
/// the real app gives it, so a widget test exercises the widget as shipped
/// rather than against a bare `MaterialApp`.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
  }) async {
    // Pump at the bible's own 390×844 design size, so `flutter_screenutil`'s
    // scale factor is 1 and every dimension a test measures is the number the
    // spec states. The default 800×600 test surface would scale widths by
    // 2.05× and heights by 0.71× and turn honest layouts into overflows.
    view
      ..physicalSize = const Size(
        Breakpoints.designWidth,
        Breakpoints.designHeight,
      )
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);

    await pumpWidget(
      ScreenUtilInit(
        designSize: const Size(
          Breakpoints.designWidth,
          Breakpoints.designHeight,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, navigatorChild) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: Theme(
              data: AppTheme.localize(
                Theme.of(context),
                Localizations.localeOf(context),
              ),
              child: navigatorChild ?? const SizedBox.shrink(),
            ),
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await pump();
  }

  /// Runs [body] against both themes, so "renders in light and dark without
  /// throwing" is one assertion rather than two copy-pasted tests.
  Future<void> pumpInBothThemes(
    Widget Function() build, {
    Future<void> Function()? body,
  }) async {
    for (final brightness in Brightness.values) {
      await pumpApp(build(), brightness: brightness);
      await body?.call();
    }
  }
}

/// Pins every mock API constructed during the test to deterministic success
/// (or, with [failureRate] of 1, to deterministic failure).
///
/// Widget tests run in debug mode, where `MockApi` fails one request in
/// twenty-five on purpose so the error states get seen during review. That is
/// right for the demo build and poison for a test suite, so any test that
/// pumps a screen which loads content calls this in its `main`.
void useMockApiFailureRate([double failureRate = 0]) {
  setUp(() => MockApi.failureRateOverride = failureRate);
  tearDown(() => MockApi.failureRateOverride = null);
}

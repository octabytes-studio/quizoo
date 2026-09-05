import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/app/app.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Exercises the RTL proof of concept from plan 001's Assumption 5: English
/// complete, a small Urdu subset, and the mirroring/typography that has to
/// work before any screen is built on top of it.
void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(
        Breakpoints.designWidth,
        Breakpoints.designHeight,
      )
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
  });

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Locale? locale,
  }) async {
    // Drive the locale the way a device does — through the platform — so the
    // test exercises MaterialApp's real locale resolution rather than an
    // override the app itself would never see.
    if (locale == null) {
      tester.platformDispatcher.clearLocalesTestValue();
    } else {
      tester.platformDispatcher.localesTestValue = [locale];
    }
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final router = AppRouter.create()..go(location);
    await tester.pumpWidget(QuizooApp(router: router));
    await tester.pumpAndSettle();
  }

  test('English and Urdu are both supported', () {
    final locales = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    expect(locales, containsAll(<String>['en', 'ur']));
  });

  test('Urdu translates the strings the RTL proof of concept needs', () async {
    final urdu = await AppLocalizations.delegate.load(const Locale('ur'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final read in <String Function(AppLocalizations)>[
      (l10n) => l10n.tabHome,
      (l10n) => l10n.tabRanks,
      (l10n) => l10n.tabDaily,
      (l10n) => l10n.tabYou,
      (l10n) => l10n.questionSample,
      (l10n) => l10n.playSheetTitle,
    ]) {
      expect(read(urdu), isNot(read(english)));
    }
  });

  testWidgets('the app is LTR in English and RTL in Urdu', (tester) async {
    await pumpAt(tester, AppRoutes.home);
    expect(
      Directionality.of(tester.element(find.byType(AppTabBar))),
      TextDirection.ltr,
    );

    await pumpAt(tester, AppRoutes.home, locale: const Locale('ur'));
    expect(
      Directionality.of(tester.element(find.byType(AppTabBar))),
      TextDirection.rtl,
    );
  });

  testWidgets('Urdu re-families the type theme to Nastaliq', (tester) async {
    await pumpAt(tester, AppRoutes.home, locale: const Locale('ur'));

    final theme = Theme.of(tester.element(find.byType(AppTabBar)));
    expect(theme.textTheme.headlineSmall!.fontFamily, AppTypography.urdu);
    expect(theme.textTheme.bodyMedium!.height, AppTypography.urduHeight);
  });

  testWidgets('the shell and the play surface hold their layout in Urdu', (
    tester,
  ) async {
    // The taller Nastaliq line-height is exactly what makes a top bar or a
    // wallet row overflow, which is why this is checked now rather than being
    // discovered in plan 004.
    for (final location in [
      AppRoutes.home,
      AppRoutes.quizPlayPath('demo'),
      AppRoutes.screenIndex,
    ]) {
      await pumpAt(tester, location, locale: const Locale('ur'));
      expect(
        tester.takeException(),
        isNull,
        reason: '$location overflows under the ur locale',
      );
    }
  });
}

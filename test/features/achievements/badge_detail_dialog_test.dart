import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/models/badge.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/features/achievements/presentation/widgets/badge_detail_dialog.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// A locked badge whose "next up" topic is *not* in the old `MockCatalog`
/// fixture — the plan-025 regression case: the CTA used to look the topic up
/// in the 26-entry fixture and threw `StateError` for anything outside it.
const _unfixturedProgress = BadgeProgress(
  badge: AppBadge(
    id: 'badge_category_king',
    name: 'Category King',
    emoji: '👑',
    description: 'Three-star every topic in one category.',
    gradientFrom: '#FFD54A',
    gradientTo: '#FF8A00',
    isLocked: true,
    rarityPercent: 4.2,
  ),
  category: BadgeCategory.skill,
  closestGroupLabel: 'SPACE · CLOSEST',
  closestFractionLabel: '3 / 8 TOPICS',
  closestProgress: 0.375,
  nextActionLabel: 'Next up: Black Holes — you’re on Level 2 of 30.',
  nextSubcategoryId: 'sub_black_holes',
  nextCategoryId: 'cat_space',
  nextSubcategoryName: 'Black Holes',
  rewardCoins: 50,
);

/// Pumps [progress]'s dialog inside a real `GoRouter`-hosted app, so the
/// dialog's `context.push` resolves — the same shape `app.dart` ships
/// (`MaterialApp.router`), which is what a dialog in this app always has.
Future<void> pumpDialog(WidgetTester tester, BadgeProgress progress) async {
  tester.view
    ..physicalSize = const Size(
      Breakpoints.designWidth,
      Breakpoints.designHeight,
    )
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => BadgeDetailDialog.show(context, progress),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      // Anything the CTA pushes lands here, which is enough to assert that
      // it navigated — and where.
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('pushed:${state.uri.path}'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(Breakpoints.designWidth, Breakpoints.designHeight),
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('BadgeDetailDialog', () {
    testWidgets(
      "a locked badge's CTA opens the correct level map for a topic outside "
      'the old MockCatalog fixture (plan 025)',
      (tester) async {
        await pumpDialog(tester, _unfixturedProgress);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(BadgeDetailDialog)),
        );
        await tester.tap(find.text(l10n.badgeDetailPlay('Black Holes')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'pushed:/category/cat_space/subcategory/sub_black_holes/levels',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a locked badge without a full next-topic route shows no CTA and does '
      'not throw',
      (tester) async {
        const noRoute = BadgeProgress(
          badge: AppBadge(
            id: 'badge_on_fire',
            name: 'On Fire',
            emoji: '🔥',
            description: 'Answer ten in a row.',
            gradientFrom: '#FF6B6B',
            gradientTo: '#C41E3A',
            isLocked: true,
            rarityPercent: 12.0,
          ),
          category: BadgeCategory.streak,
        );

        await pumpDialog(tester, noRoute);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(BadgeDetailDialog)),
        );
        expect(find.text(l10n.commonClose), findsOneWidget);
        expect(find.textContaining('Play'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

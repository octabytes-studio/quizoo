import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/app/app.dart';

import '../support/pump_app.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';

void main() {
  useMockApiFailureRate();

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

  testWidgets('the app boots and reaches the Home tab', (tester) async {
    final router = AppRouter.create()..go(AppRoutes.home);
    await tester.pumpWidget(QuizooApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(AppTabBar), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ThemeCubit re-themes the whole shell', (tester) async {
    final router = AppRouter.create()..go(AppRoutes.home);
    await tester.pumpWidget(QuizooApp(router: router));
    await tester.pumpAndSettle();

    QuizooColors tokens() => tester.element(find.byType(AppTabBar)).quizoo;

    final cubit = tester.element(find.byType(AppTabBar)).read<ThemeCubit>();

    cubit.setLight();
    await tester.pumpAndSettle();
    expect(tokens().s0, AppColors.lightS0);
    expect(tokens().tx, AppColors.lightTx);

    cubit.setDark();
    await tester.pumpAndSettle();
    expect(tokens().s0, AppColors.darkS0);
    expect(tokens().tx, AppColors.darkTx);
  });
}

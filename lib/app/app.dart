import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The application root.
///
/// Three things live here and nowhere else: the single [ScreenUtilInit] (at
/// the bible's 390×844 design size), the [MaterialApp.router] carrying both
/// `ThemeData`s, and the one legitimately app-wide `BlocProvider` — the
/// [ThemeCubit].
class QuizooApp extends StatefulWidget {
  const QuizooApp({super.key, this.router});

  /// Overridable so a test can pump the app against its own router.
  final GoRouter? router;

  @override
  State<QuizooApp> createState() => _QuizooAppState();
}

class _QuizooAppState extends State<QuizooApp> {
  late final GoRouter _router = widget.router ?? AppRouter.create();

  @override
  void initState() {
    super.initState();
    // §05: every screen's own background runs behind the status bar and the
    // navigation bar. Set once here; per-route icon brightness comes from each
    // screen's `AppBarTheme.systemOverlayStyle`.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: ScreenUtilInit(
        designSize: const Size(
          Breakpoints.designWidth,
          Breakpoints.designHeight,
        ),
        minTextAdapt: true,
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp.router(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.mode.toThemeMode(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              // The locale-dependent half of the type system — Nastaliq
              // families and their taller line-height — can only be applied
              // below `Localizations`, which is here.
              builder: (context, child) => Theme(
                data: AppTheme.localize(
                  Theme.of(context),
                  Localizations.localeOf(context),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}

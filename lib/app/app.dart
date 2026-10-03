import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/app/locale_cubit.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/ads/admob_inline_ad_service.dart';
import 'package:quizoo/core/ads/admob_interstitial_ad_service.dart';
import 'package:quizoo/core/ads/ads_config_api.dart';
import 'package:quizoo/core/ads/ads_config_repository.dart';
import 'package:quizoo/core/ads/ads_pacing_store.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/ads/interstitial_pacer.dart';
import 'package:quizoo/core/ads/ump_ad_consent_service.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/content_language/content_language_api.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/ladder/ladder_config_api.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/subscription/pro_status_api.dart';
import 'package:quizoo/core/subscription/revenuecat_config.dart';
import 'package:quizoo/core/subscription/revenuecat_purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

/// The application root.
///
/// Four things live here and nowhere else: the single [ScreenUtilInit] (at
/// the bible's 390×844 design size), the [MaterialApp.router] carrying both
/// `ThemeData`s, the genuinely app-wide Cubits, and the two mock repositories
/// that hold session-lifetime state.
///
/// **What earns an app-root `BlocProvider`** (CLAUDE.md §3 is explicit that
/// this is the exception, not the default): [ThemeCubit] and [LocaleCubit],
/// because every screen renders through them, and [SessionCubit], which
/// §3 names by example — Home switches its entire layout on it and plans 003
/// and 004 read it for the profile tab and the player's own leaderboard row.
/// [ConnectivityCubit] joins them in plan 004: Settings' debug "Simulate
/// offline" toggle and Home's offline variant (S-46) are on different
/// routes, so the flag has to live above both.
///
/// **Why the `RepositoryProvider`s**: each of the three holds state that
/// outlives any one screen's Cubit, written on one route and read on another.
/// [OnboardingRepository] remembers that first-run happened; [AuthRepository]
/// remembers whether the save-progress sheet has already been offered; and
/// [QuizPlayRepository] is the prefetch cache the level brief sheet (S-09)
/// warms and the play surface (S-11) reads, on a different route. All three
/// are in-memory for this phase; see each class for what that costs.
///
/// Plan 017 adds [DuelRealtime] and [ServerClock]: the Duel Arena,
/// matchmaking and live-duel screens are stacked routes that all listen to
/// the same `duel-user:<uid>` inbox channel (ref-counted, so it is joined
/// once) and all show countdowns that must agree with the server, so both
/// live above any one of them — one channel per topic, one clock offset.
///
/// Plan 022 adds [AdsCubit] and the [InlineAdService] it sits beside: every
/// tab and seven features host a banner, a native ad or an interstitial
/// break, and all of them must share one consent result, one remote config
/// and one pacing clock — a per-screen Cubit would let two screens show
/// interstitials back to back. Consent and the ad SDK start from here,
/// un-awaited, so neither is on the startup path.
///
/// Plan 023 adds [SubscriptionCubit], beside [AdsCubit] for the same reason
/// and for one more: it is the single source of "is this player Pro", which
/// eight features read, and it is the switch [AdsCubit.setAdFree] follows —
/// a member must stop seeing ads everywhere the moment the store confirms
/// the purchase, with no screen rebuilding its own idea of it. Its two
/// session-lifetime collaborators are the [RepositoryProvider]s
/// [SubscriptionRepository] (the purchase seam, shared with the paywall) and
/// [ProPromoStore] (the Home card dismissal clock and the post-interstitial
/// offer counter, written from `core/widgets/ad_break.dart`).
class QuizooApp extends StatefulWidget {
  const QuizooApp({
    required this.preferences,
    super.key,
    this.router,
    this.adsCubit,
    this.subscriptionCubit,
  });

  /// Overridable so a test can pump the app against its own router.
  final GoRouter? router;

  /// Overridable so a test never reaches the ad SDK, Remote Config or UMP.
  /// When null the app builds the real one and starts it.
  final AdsCubit? adsCubit;

  /// Overridable so a test never reaches the purchase SDK. When null the app
  /// builds the real one and starts it.
  final SubscriptionCubit? subscriptionCubit;

  /// Backs [OnboardingRepository] and [AuthRepository]'s device-local flags.
  /// Obtained once in `main()`, before `runApp`, since loading it is async.
  final SharedPreferences preferences;

  @override
  State<QuizooApp> createState() => _QuizooAppState();
}

class _QuizooAppState extends State<QuizooApp> {
  late final GoRouter _router = widget.router ?? AppRouter.create();
  late final OnboardingRepository _onboardingRepository = OnboardingRepository(
    widget.preferences,
  );
  late final AuthRepository _authRepository = AuthRepository(
    AuthApi(supabase),
    widget.preferences,
  );
  late final QuizPlayRepository _quizPlayRepository = QuizPlayRepository(
    QuizPlayApi(supabase),
  );
  late final SettingsRepository _settingsRepository = SettingsRepository(
    widget.preferences,
  );
  late final LadderConfigRepository _ladderConfigRepository =
      LadderConfigRepository(LadderConfigApi(supabase));
  late final ContentLanguageRepository _contentLanguageRepository =
      ContentLanguageRepository(
        ContentLanguageApi(supabase),
        widget.preferences,
      );
  late final ContentLanguageCubit _contentLanguageCubit = ContentLanguageCubit(
    _contentLanguageRepository,
  );
  late final SessionCubit _sessionCubit = SessionCubit(_authRepository);
  late final DuelRealtime _duelRealtime = DuelRealtime(supabase);
  late final ServerClock _serverClock = ServerClock();
  late final InlineAdService _inlineAdService = AdMobInlineAdService();
  late final AdsCubit _adsCubit = widget.adsCubit ?? _createAdsCubit();
  late final ProPromoStore _proPromoStore = ProPromoStore(widget.preferences);
  late final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository(
        RevenueCatPurchasesService(),
        ProStatusApi(supabase),
        widget.preferences,
      );
  late final SubscriptionCubit _subscriptionCubit =
      widget.subscriptionCubit ?? _createSubscriptionCubit();

  /// The purchase SDK's key for this platform (plan 023, Assumption 8):
  /// release builds use the real store key, debug builds use RevenueCat's
  /// Test Store, and `--dart-define=RC_USE_REAL_STORE=true` opts a debug
  /// build into the sandbox stores. Null on web/desktop — Pro is simply
  /// unavailable there.
  String? get _revenueCatApiKey => RevenueCatConfig.apiKeyFor(
    defaultTargetPlatform,
    useRealStore: const bool.fromEnvironment('RC_USE_REAL_STORE'),
  );

  SubscriptionCubit _createSubscriptionCubit() => SubscriptionCubit(
    repository: _subscriptionRepository,
    promos: _proPromoStore,
    userIds: _authRepository.authStateChanges.map(_identityFromAuthState),
    initialUserId: supabase.auth.currentUser?.id,
    apiKey: _revenueCatApiKey,
    // Remote Config is only reachable once Firebase is initialised; a test
    // that builds the real Cubit without it must get "Pro is on" rather than
    // a crash (plan 023's `pro_enabled` master switch).
    isEnabled: _proEnabled,
  );

  bool get _proEnabled {
    try {
      return FirebaseRemoteConfig.instance.getBool('pro_enabled');
    } on Object {
      return true;
    }
  }

  /// Supabase's auth stream, shaped for the subscription layer: a null id
  /// means signed out, and `isAnonymous` decides whether a Pro purchase is
  /// carried onto the new id (plan 023, "Identity").
  static UserIdentity? _identityFromAuthState(AuthState authState) {
    final user = authState.session?.user;
    if (user == null) return null;
    return (id: user.id, isAnonymous: user.isAnonymous);
  }

  AdsCubit _createAdsCubit() => AdsCubit(
    consent: UmpAdConsentService(),
    config: AdsConfigRepository(AdsConfigApi(FirebaseRemoteConfig.instance)),
    interstitial: AdMobInterstitialAdService(
      isMuted: () => !_settingsRepository.current.soundOn,
    ),
    pacer: InterstitialPacer(AdsPacingStore(widget.preferences)),
    initializeSdk: _initializeAdsSdk,
    isSupportedPlatform:
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS),
  );

  /// Runs only once consent allows ad requests (see [AdsCubit.initialize]).
  static Future<void> _initializeAdsSdk() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
    await MobileAds.instance.initialize();
  }

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
    // Restores `SessionSignedIn` across a cold start for a previously
    // signed-in player — a real Supabase session persists where the mock's
    // never did (plan 005, Design overview).
    unawaited(_sessionCubit.restore());
    // Fetched once for the process lifetime, same shape as the ladder's own
    // "select for everyone" reference tables (plan 007, Design overview).
    // Best-effort: a failure here isn't fatal — whichever catalog screen
    // needs it next calls `ensureLoaded()` again and surfaces its own error
    // state, the same way every other content fetch already does.
    unawaited(_ladderConfigRepository.ensureLoaded().catchError((_) {}));
    // Pro first, then ads: a returning member must be ad-free before the
    // first ad slot ever asks whether it may render (plan 023). An injected
    // Cubit is the test's to drive.
    if (widget.subscriptionCubit == null) {
      unawaited(_subscriptionCubit.initialize());
    }
    if (widget.adsCubit == null) {
      _adsCubit.setAdFree(_subscriptionCubit.state.isPro);
      // Consent first, then the ad SDK — never awaited, so a slow consent
      // round trip cannot hold up the first frame.
      unawaited(_adsCubit.initialize());
    }
  }

  @override
  void dispose() {
    unawaited(_sessionCubit.close());
    if (widget.adsCubit == null) unawaited(_adsCubit.close());
    if (widget.subscriptionCubit == null) {
      unawaited(_subscriptionCubit.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OnboardingRepository>.value(
          value: _onboardingRepository,
        ),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<QuizPlayRepository>.value(
          value: _quizPlayRepository,
        ),
        RepositoryProvider<SettingsRepository>.value(
          value: _settingsRepository,
        ),
        RepositoryProvider<LadderConfigRepository>.value(
          value: _ladderConfigRepository,
        ),
        RepositoryProvider<ContentLanguageRepository>.value(
          value: _contentLanguageRepository,
        ),
        RepositoryProvider<DuelRealtime>.value(value: _duelRealtime),
        RepositoryProvider<ServerClock>.value(value: _serverClock),
        RepositoryProvider<InlineAdService>.value(value: _inlineAdService),
        RepositoryProvider<SubscriptionRepository>.value(
          value: _subscriptionRepository,
        ),
        RepositoryProvider<ProPromoStore>.value(value: _proPromoStore),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
          BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
          BlocProvider<SessionCubit>.value(value: _sessionCubit),
          BlocProvider<ContentLanguageCubit>.value(
            value: _contentLanguageCubit,
          ),
          BlocProvider<AdsCubit>.value(value: _adsCubit),
          BlocProvider<SubscriptionCubit>.value(value: _subscriptionCubit),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<SessionCubit, SessionState>(
              // Reconciles a *returning* signed-in identity's own
              // `profiles.locale` against this device's local cache — gated
              // on an actual sign-in completion so it can never race the
              // mandatory first-launch picker on a genuinely fresh install
              // (plan 008, Assumption 2).
              listenWhen: (previous, current) =>
                  current is SessionSignedIn && previous is! SessionSignedIn,
              listener: (context, state) => unawaited(
                context.read<ContentLanguageCubit>().adoptFromBackend(),
              ),
            ),
            BlocListener<SubscriptionCubit, SubscriptionState>(
              // The one place the entitlement reaches the ad layer (plan
              // 023): the moment Pro flips, every slot and every
              // interstitial goes with it — and comes back the moment it
              // lapses. `listenWhen` on the flag so an unrelated state
              // change never re-emits `AdsReady`.
              listenWhen: (previous, current) =>
                  previous.isPro != current.isPro,
              listener: (context, state) =>
                  context.read<AdsCubit>().setAdFree(state.isPro),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(
              Breakpoints.designWidth,
              Breakpoints.designHeight,
            ),
            minTextAdapt: true,
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return BlocBuilder<LocaleCubit, LocaleState>(
                  builder: (context, localeState) {
                    return MaterialApp.router(
                      onGenerateTitle: (context) =>
                          AppLocalizations.of(context).appTitle,
                      debugShowCheckedModeBanner: false,
                      routerConfig: _router,
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      themeMode: themeState.mode.toThemeMode(),
                      // Null follows the device. A language this build does
                      // not translate resolves back to English by Flutter's
                      // own rules, which is exactly what S-03 warns about on
                      // screen.
                      locale: localeState.locale,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: AppLocalizations.supportedLocales,
                      // The locale-dependent half of the type system —
                      // Nastaliq families and their taller line-height — can
                      // only be applied below `Localizations`, which is here.
                      builder: (context, child) => Theme(
                        data: AppTheme.localize(
                          Theme.of(context),
                          Localizations.localeOf(context),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

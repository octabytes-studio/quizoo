import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quizoo/app/app.dart';
import 'package:quizoo/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  // Every guest gets a real anonymous session, invisibly, the moment the app
  // launches — RLS throughout the schema gates on auth.uid(), which a guest
  // only has via a real session (plan 005, Assumption #4). Never surfaced to
  // the player: `SessionCubit`'s initial state stays `SessionGuest`.
  if (Supabase.instance.client.auth.currentSession == null) {
    await Supabase.instance.client.auth.signInAnonymously();
  }

  final preferences = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: fatal Flutter errors and anything escaping the zone.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  unawaited(FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true));

  // Remote Config: defaults match docs/backend/02-firebase-project-setup.md
  // §3's table exactly, so an offline first launch or a fetch failure never
  // leaves the app without a sane number to show.
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: kDebugMode
          ? Duration.zero
          : const Duration(hours: 1),
    ),
  );
  await remoteConfig.setDefaults(const {
    'daily_challenge_coin_reward': 300,
    'daily_challenge_xp_reward': 500,
    'heart_refill_minutes': 20,
    'duel_winner_coins': 200,
    'duel_loser_coins': 40,
    'coin_pack_ids': '["pack_small","pack_medium","pack_large"]',
    'save_progress_prompt_enabled': true,
  });
  unawaited(remoteConfig.fetchAndActivate());

  runApp(QuizooApp(preferences: preferences));
}

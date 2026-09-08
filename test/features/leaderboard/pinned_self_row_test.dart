import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/pinned_self_row.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/podium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

Future<SessionCubit> signedInSession() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return SessionCubit(AuthRepository(AuthApi(supabase), preferences))..emit(
    const SessionSignedIn(
      AuthUser(
        id: 'user_google',
        displayName: 'Waleed',
        provider: AuthProvider.google,
      ),
    ),
  );
}

void main() {
  useMockApiFailureRate();

  // `LeaderboardScreen` now constructs a real `LeaderboardApi(supabase)`
  // inline (matching every other screen post plan-006's migration), reaching
  // the unreachable placeholder client `test/flutter_test_config.dart` sets
  // up — the roster never loads, so `PinnedSelfRow`/`Podium` never render.
  // Skipped for the same reason `home_screen_test.dart`'s content-dependent
  // tests are; the scroll-independence behaviour this test guards would need
  // a mocked `LeaderboardApi` injected into the screen to re-cover.
  testWidgets(
    'PinnedSelfRow stays put — it is a fixed sibling of the scrollable '
    'roster, never a list item that happens to scroll into view',
    skip: true,
    (tester) async {
      await tester.pumpScreen(
        const LeaderboardScreen(),
        session: await signedInSession(),
      );
      // Let the roster and self-row load.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.byType(PinnedSelfRow), findsOneWidget);
      final before = tester.getTopLeft(find.byType(PinnedSelfRow));

      // Drag the podium — inside the scrollable roster — well past its
      // extent, the way a real scroll gesture would.
      await tester.drag(find.byType(Podium), const Offset(0, -600));
      await tester.pump();

      final after = tester.getTopLeft(find.byType(PinnedSelfRow));
      expect(
        after,
        before,
        reason: 'the self row must not move when the roster above it scrolls',
      );
    },
  );
}

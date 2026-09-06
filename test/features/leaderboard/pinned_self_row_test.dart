import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/pinned_self_row.dart';
import 'package:quizoo/features/leaderboard/presentation/widgets/podium.dart';

import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

void main() {
  useMockApiFailureRate();

  SessionCubit signedInSession() =>
      SessionCubit(AuthRepository(AuthApi()))..emit(
        const SessionSignedIn(
          AuthUser(
            id: 'user_google',
            displayName: 'Waleed',
            provider: AuthProvider.google,
          ),
        ),
      );

  testWidgets(
    'PinnedSelfRow stays put — it is a fixed sibling of the scrollable '
    'roster, never a list item that happens to scroll into view',
    (tester) async {
      await tester.pumpScreen(
        const LeaderboardScreen(),
        session: signedInSession(),
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

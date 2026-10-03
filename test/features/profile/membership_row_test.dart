import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/widgets/app_mark.dart';
import 'package:quizoo/features/profile/presentation/widgets/membership_row.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/fake_purchases.dart';
import '../../support/pump_screen.dart';

void main() {
  /// The row reads `SubscriptionCubit` for the renewal date and pushes
  /// routes on tap, so it needs both app-root pieces `pumpScreen` gives it.
  Future<AppLocalizations> pumpRow(
    WidgetTester tester, {
    required bool isPro,
    ProMembership? membership,
  }) async {
    final cubit = membership == null
        ? freeSubscriptionCubit()
        : proSubscriptionCubitWith(membership);
    addTearDown(cubit.close);
    // A fresh Cubit's state knows only the cached `isPro` flag; the
    // membership detail (plan, expiry) arrives with the first snapshot.
    await cubit.refresh();
    await tester.pumpScreen(
      SubscriptionCubitWrapped(
        cubit: cubit,
        child: MembershipRow(isPro: isPro),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(MembershipRow)));
  }

  group('MembershipRow', () {
    testWidgets('a member sees the renewal date beneath the title', (
      tester,
    ) async {
      final l10n = await pumpRow(
        tester,
        isPro: true,
        membership: ProMembership(
          plan: ProPlan.monthly,
          expiresAt: DateTime(2026, 11, 1),
          willRenew: true,
        ),
      );

      expect(find.text(l10n.proMembershipActive), findsOneWidget);
      final subtitle = tester.widget<Text>(find.textContaining('Renews on '));
      expect(subtitle.data, contains('2026'));
    });

    testWidgets('a lifetime member sees the lifetime label, not a date', (
      tester,
    ) async {
      final l10n = await pumpRow(
        tester,
        isPro: true,
        membership: const ProMembership(plan: ProPlan.lifetime),
      );

      expect(find.text(l10n.proMembershipActive), findsOneWidget);
      expect(find.text('Lifetime member'), findsOneWidget);
      expect(find.textContaining('Renews on '), findsNothing);
    });

    testWidgets('a cancelled member sees the end date', (tester) async {
      await pumpRow(
        tester,
        isPro: true,
        membership: ProMembership(
          plan: ProPlan.yearly,
          expiresAt: DateTime(2026, 11, 1),
          willRenew: false,
        ),
      );

      expect(find.textContaining('Ends on '), findsOneWidget);
    });

    testWidgets('the leading plate is the app mark and never a crown', (
      tester,
    ) async {
      await pumpRow(
        tester,
        isPro: true,
        membership: const ProMembership(plan: ProPlan.lifetime),
      );

      expect(find.byType(AppMark), findsOneWidget);
      expect(find.text('👑'), findsNothing);
      expect(find.text('🦉'), findsNothing);
    });

    testWidgets('a free player sees the Go Pro pitch instead', (tester) async {
      final l10n = await pumpRow(tester, isPro: false);

      expect(find.text(l10n.proGoPro), findsOneWidget);
      expect(find.text(l10n.proGoProCardBody), findsOneWidget);
      expect(find.textContaining('Renews on '), findsNothing);
    });
  });
}

/// `pumpScreen` already provides a `SubscriptionCubit`; this re-provides it
/// so a test can drive a specific membership without duplicating the rest of
/// the harness.
class SubscriptionCubitWrapped extends StatelessWidget {
  const SubscriptionCubitWrapped({
    required this.child,
    required this.cubit,
    super.key,
  });

  final Widget child;
  final SubscriptionCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionCubit>.value(value: cubit, child: child);
  }
}

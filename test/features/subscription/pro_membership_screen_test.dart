import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/features/subscription/presentation/screens/pro_membership_screen.dart';

import '../../support/fake_purchases.dart';
import '../../support/pump_screen.dart';

/// A [SubscriptionCubit] holding [membership] on this device, with its
/// [FakePurchasesService] exposed so a test can assert what was called.
Future<SubscriptionCubit> memberCubit(
  FakePurchasesService purchases,
  ProMembership membership,
) async {
  final preferences = MemoryPreferences();
  await preferences.setBool('subscription.isPro', true);
  purchases.emitSnapshot(
    PurchasesSnapshot(isPro: true, membership: membership),
  );
  final cubit = SubscriptionCubit(
    repository: SubscriptionRepository(
      purchases,
      FakeProStatusApi(),
      preferences,
    ),
    promos: ProPromoStore(preferences),
    userIds: const Stream.empty(),
    initialUserId: 'user-1',
    apiKey: 'test-key',
    isEnabled: true,
  );
  await cubit.initialize();
  return cubit;
}

/// Pumps the membership screen and lets the hero's entrance stagger finish,
/// so no animation timer outlives the test.
Future<void> pumpMembership(
  WidgetTester tester,
  SubscriptionCubit cubit,
) async {
  await tester.pumpScreen(
    ProMembershipScreen(),
    subscription: cubit,
    disableAnimations: true,
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> revealManageButton(WidgetTester tester) =>
    tester.scrollUntilVisible(
      find.text('Manage subscription'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

void main() {
  testWidgets('Manage subscription is offered without an SDK management URL', (
    tester,
  ) async {
    final purchases = FakePurchasesService();
    // The Test Store / sandbox case that used to hide the button entirely:
    // RevenueCat reports no managementURL, so the store fallback must carry
    // the player to the cancellation page.
    final cubit = await memberCubit(
      purchases,
      const ProMembership(plan: ProPlan.monthly, willRenew: true),
    );
    addTearDown(cubit.close);

    await pumpMembership(tester, cubit);
    await revealManageButton(tester);
    expect(find.text('Manage subscription'), findsOneWidget);

    await tester.tap(find.text('Manage subscription'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(purchases.calls, contains('openManagement'));
    expect(find.textContaining("Couldn't open the store"), findsNothing);
  });

  testWidgets('Manage subscription is hidden for a lifetime purchase', (
    tester,
  ) async {
    final purchases = FakePurchasesService();
    final cubit = await memberCubit(
      purchases,
      const ProMembership(plan: ProPlan.lifetime),
    );
    addTearDown(cubit.close);

    await pumpMembership(tester, cubit);
    expect(find.text('Lifetime member'), findsOneWidget);

    // Past the manage slot, so "absent" cannot just mean "not scrolled to".
    await tester.scrollUntilVisible(
      find.text('Restore purchases'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Manage subscription'), findsNothing);
  });

  testWidgets('a store page that cannot open is said out loud', (tester) async {
    final purchases = FakePurchasesService()..openManagementResult = false;
    final cubit = await memberCubit(
      purchases,
      const ProMembership(plan: ProPlan.yearly, willRenew: true),
    );
    addTearDown(cubit.close);

    await pumpMembership(tester, cubit);
    await revealManageButton(tester);
    await tester.tap(find.text('Manage subscription'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("Couldn't open the store"), findsOneWidget);

    // Let the snackbar time out so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
  });
}

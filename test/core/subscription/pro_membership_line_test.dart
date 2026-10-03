import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_membership_line.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';

import '../../support/pump_app.dart';

void main() {
  group('membershipLineOf', () {
    test('a lifetime plan says lifetime, whatever else is on it', () {
      expect(
        membershipLineOf(
          const ProMembership(plan: ProPlan.lifetime, willRenew: true),
        ),
        ProMembershipLine.lifetime,
      );
    });

    test(
      'a trial is reported before the expiry it shares with a paid plan',
      () {
        expect(
          membershipLineOf(
            ProMembership(
              plan: ProPlan.yearly,
              isTrial: true,
              expiresAt: DateTime(2026, 11, 1),
              willRenew: true,
            ),
          ),
          ProMembershipLine.inTrial,
        );
      },
    );

    test('a renewing subscription says so', () {
      expect(
        membershipLineOf(
          ProMembership(
            plan: ProPlan.monthly,
            expiresAt: DateTime(2026, 11, 1),
            willRenew: true,
          ),
        ),
        ProMembershipLine.renewsOn,
      );
    });

    test('a cancelled subscription ends instead of renewing', () {
      expect(
        membershipLineOf(
          ProMembership(
            plan: ProPlan.monthly,
            expiresAt: DateTime(2026, 11, 1),
            willRenew: false,
          ),
        ),
        ProMembershipLine.endsOn,
      );
    });

    test('no membership and no date both fall back to "active"', () {
      expect(membershipLineOf(null), ProMembershipLine.none);
      expect(
        membershipLineOf(const ProMembership(plan: ProPlan.yearly)),
        ProMembershipLine.none,
      );
    });
  });

  group('proMembershipLineLabel', () {
    Future<String> label(
      WidgetTester tester, {
      required ProMembershipLine line,
      DateTime? expiresAt,
    }) async {
      late String value;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            value = proMembershipLineLabel(
              context,
              line: line,
              expiresAt: expiresAt,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      return value;
    }

    testWidgets('lifetime reads "Lifetime member"', (tester) async {
      final text = await label(tester, line: ProMembershipLine.lifetime);
      expect(text, 'Lifetime member');
    });

    testWidgets('a renewing plan names the renewal date', (tester) async {
      final text = await label(
        tester,
        line: ProMembershipLine.renewsOn,
        expiresAt: DateTime(2026, 11, 1),
      );
      expect(text, startsWith('Renews on '));
      expect(text, contains('2026'));
    });

    testWidgets('a cancelled plan names the end date', (tester) async {
      final text = await label(
        tester,
        line: ProMembershipLine.endsOn,
        expiresAt: DateTime(2026, 11, 1),
      );
      expect(text, startsWith('Ends on '));
    });

    testWidgets('a trial names the first charge date', (tester) async {
      final text = await label(
        tester,
        line: ProMembershipLine.inTrial,
        expiresAt: DateTime(2026, 11, 1),
      );
      expect(text, startsWith('Free trial'));
    });

    testWidgets('no date at all still reads as an active membership', (
      tester,
    ) async {
      final text = await label(tester, line: ProMembershipLine.none);
      expect(text, 'Membership active');
    });

    testWidgets('a date line with no date does not crash', (tester) async {
      final text = await label(tester, line: ProMembershipLine.renewsOn);
      expect(text, startsWith('Renews on '));
      expect(tester.takeException(), isNull);
    });
  });
}

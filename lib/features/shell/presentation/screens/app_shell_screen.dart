import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';

/// The five-tab shell every non-play screen lives inside.
///
/// Owns the `Scaffold` whose `bottomNavigationBar` slot pins [AppTabBar], and
/// nothing else — branch switching is `StatefulShellRoute`'s job, and the
/// centre FAB pushes the full-screen Duel Arena over the shell (plan 017).
class AppShellScreen extends StatelessWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  /// The four tab branches, kept alive in an `IndexedStack` so switching tabs
  /// preserves each one's scroll position and navigation stack.
  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int branch) {
    navigationShell.goBranch(
      branch,
      // Tapping the tab you are already on pops that branch back to its root.
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The shell body is edge-to-edge: each screen's own background runs
      // behind the status bar, so no SafeArea wraps it here (§05).
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: _onTabSelected,
        onPlayPressed: () => context.push(AppRoutes.duelArena),
      ),
    );
  }
}

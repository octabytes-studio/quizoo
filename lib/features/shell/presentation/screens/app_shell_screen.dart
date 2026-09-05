import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/features/shell/presentation/widgets/app_tab_bar.dart';
import 'package:quizoo/features/shell/presentation/widgets/play_launcher_sheet.dart';

/// The five-tab shell every non-play screen lives inside.
///
/// Owns the `Scaffold` whose `bottomNavigationBar` slot pins [AppTabBar], and
/// nothing else — branch switching is `StatefulShellRoute`'s job and the tab
/// bar's own state is `isPlaySheetOpen`, which is exactly the kind of purely
/// local, no-business-meaning UI state `setState` exists for (CLAUDE.md §3).
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  /// The four tab branches, kept alive in an `IndexedStack` so switching tabs
  /// preserves each one's scroll position and navigation stack.
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  bool _isPlaySheetOpen = false;

  Future<void> _openPlaySheet() async {
    if (_isPlaySheetOpen) {
      Navigator.of(context, rootNavigator: true).maybePop();
      return;
    }
    setState(() => _isPlaySheetOpen = true);
    await PlayLauncherSheet.show(context);
    if (mounted) setState(() => _isPlaySheetOpen = false);
  }

  void _onTabSelected(int branch) {
    widget.navigationShell.goBranch(
      branch,
      // Tapping the tab you are already on pops that branch back to its root.
      initialLocation: branch == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The shell body is edge-to-edge: each screen's own background runs
      // behind the status bar, so no SafeArea wraps it here (§05).
      body: widget.navigationShell,
      bottomNavigationBar: AppTabBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTabSelected: _onTabSelected,
        onPlayPressed: _openPlaySheet,
        isPlaySheetOpen: _isPlaySheetOpen,
      ),
    );
  }
}

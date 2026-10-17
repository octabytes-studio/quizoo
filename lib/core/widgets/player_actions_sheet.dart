import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/safety/domain/player_report_reason.dart';
import 'package:quizoo/core/safety/safety_api.dart';
import 'package:quizoo/core/safety/safety_cubit.dart';
import 'package:quizoo/core/safety/safety_repository.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The shared report/block entry point for any player row (plan 025) — the
/// leaderboard podium and rows today; any future player surface gets the same
/// behaviour by opening this one sheet.
///
/// The flow: the sheet opens on the two actions; "Report player" swaps the
/// body for the reason list; block/unblock fires immediately. A block/unblock
/// resolves the sheet's own future with `true`, so the caller can reload the
/// list it opened this from (the blocked player disappears, an unblocked one
/// returns).
class PlayerActionsSheet extends StatelessWidget {
  const PlayerActionsSheet({
    required this.playerId,
    required this.playerName,
    required this.isBlocked,
    @visibleForTesting this.safetyRepository,
    super.key,
  });

  final String playerId;
  final String playerName;

  /// Whether the viewer currently blocks this player — always false from the
  /// leaderboard (its own roster filter already hides blocked players), but
  /// the caller decides so the sheet stays reusable.
  final bool isBlocked;

  /// Test seam: drives the sheet from a fake repository instead of the real
  /// backend.
  final SafetyRepository? safetyRepository;

  /// Opens the sheet and resolves `true` when a block state changed.
  static Future<bool?> show(
    BuildContext context, {
    required String playerId,
    required String playerName,
    required bool isBlocked,
  }) {
    return AppBottomSheet.show<bool>(
      context,
      builder: (_) => PlayerActionsSheet(
        playerId: playerId,
        playerName: playerName,
        isBlocked: isBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SafetyCubit>(
      create: (_) => SafetyCubit(
        safetyRepository ?? SafetyRepository(SafetyApi(supabase)),
        playerId: playerId,
        isBlocked: isBlocked,
      ),
      child: _PlayerActionsView(playerName: playerName),
    );
  }
}

class _PlayerActionsView extends StatefulWidget {
  const _PlayerActionsView({required this.playerName});

  final String playerName;

  @override
  State<_PlayerActionsView> createState() => _PlayerActionsViewState();
}

class _PlayerActionsViewState extends State<_PlayerActionsView> {
  /// Purely local view state (CLAUDE.md §3): which body the sheet shows.
  bool _isReporting = false;
  int? _selectedReason;

  static String _reasonLabel(
    AppLocalizations l10n,
    PlayerReportReason reason,
  ) => switch (reason) {
    PlayerReportReason.offensiveName => l10n.safetyReasonOffensiveName,
    PlayerReportReason.harassment => l10n.safetyReasonHarassment,
    PlayerReportReason.cheating => l10n.safetyReasonCheating,
    PlayerReportReason.impersonation => l10n.safetyReasonImpersonation,
    PlayerReportReason.other => l10n.safetyReasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.watch<SafetyCubit>();
    final isBusy = cubit.state is SafetyBusy;

    return AppBottomSheet(
      // The title is data, not copy: it names exactly who the actions apply
      // to.
      title: widget.playerName,
      message: l10n.safetyBlockHelper,
      child: BlocListener<SafetyCubit, SafetyState>(
        listenWhen: (previous, current) =>
            current is SafetyDone || current is SafetyFailed,
        listener: (context, state) {
          switch (state) {
            case SafetyDone(:final outcome):
              AppSnackbar.show(
                context,
                title: switch (outcome) {
                  SafetyOutcome.blocked => l10n.safetyBlocked,
                  SafetyOutcome.unblocked => l10n.safetyUnblocked,
                  SafetyOutcome.reported => l10n.safetyReportSent,
                },
                intent: SnackbarIntent.success,
              );
              Navigator.of(context).pop(outcome != SafetyOutcome.reported);
            case SafetyFailed():
              AppSnackbar.show(
                context,
                title: l10n.safetyActionFailed,
                intent: SnackbarIntent.error,
              );
            case SafetyIdle() || SafetyBusy():
              break;
          }
        },
        child: _isReporting
            ? _ReportReasons(
                selectedIndex: _selectedReason,
                isBusy: isBusy,
                onSelect: (index) => setState(() => _selectedReason = index),
                onSubmit: _selectedReason == null
                    ? null
                    : () => cubit.report(
                        PlayerReportReason.values[_selectedReason!],
                      ),
                onBack: () => setState(() {
                  _isReporting = false;
                  _selectedReason = null;
                }),
              )
            : _Actions(
                isBlocked: cubit.isBlocked,
                isBusy: isBusy,
                onReport: () => setState(() => _isReporting = true),
                onToggleBlock: cubit.toggleBlock,
              ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isBlocked,
    required this.isBusy,
    required this.onReport,
    required this.onToggleBlock,
  });

  final bool isBlocked;
  final bool isBusy;
  final VoidCallback onReport;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListRowTile(
          title: l10n.safetyReportPlayer,
          leadingEmoji: '🚩',
          onTap: isBusy ? null : onReport,
        ),
        SizedBox(height: 9.h),
        ListRowTile(
          title: isBlocked ? l10n.safetyUnblockPlayer : l10n.safetyBlockPlayer,
          leadingEmoji: isBlocked ? '🔓' : '🚫',
          onTap: isBusy ? null : onToggleBlock,
        ),
        if (isBusy) ...[
          SizedBox(height: AppSpacing.sm.h),
          Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.quizoo.g,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportReasons extends StatelessWidget {
  const _ReportReasons({
    required this.selectedIndex,
    required this.isBusy,
    required this.onSelect,
    required this.onSubmit,
    required this.onBack,
  });

  final int? selectedIndex;
  final bool isBusy;
  final ValueChanged<int> onSelect;
  final VoidCallback? onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, reason) in PlayerReportReason.values.indexed) ...[
            if (index > 0) SizedBox(height: 9.h),
            ListRowTile(
              title: _PlayerActionsViewState._reasonLabel(l10n, reason),
              padding: EdgeInsets.all(13.w),
              accentColor: selectedIndex == index ? quizoo.g : null,
              trailing: Text(
                selectedIndex == index ? '●' : '○',
                style: AppTypography.glyph(
                  14.sp,
                  color: selectedIndex == index ? quizoo.g : quizoo.tx3,
                ),
              ),
              onTap: isBusy ? null : () => onSelect(index),
            ),
          ],
          SizedBox(height: 14.h),
          ChunkyButton(
            label: l10n.safetyReportSubmit,
            onPressed: isBusy ? null : onSubmit,
          ),
          SizedBox(height: 9.h),
          ChunkyButton.line(label: l10n.commonBack, onPressed: onBack),
          SizedBox(height: AppSpacing.xs.h),
        ],
      ),
    );
  }
}

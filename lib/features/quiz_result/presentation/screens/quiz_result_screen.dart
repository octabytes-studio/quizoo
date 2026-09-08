import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_api.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_repository.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/level_complete_screen.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/level_failed_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The route host behind S-21 and S-22.
///
/// Both bible screens share one entry point, because every way a level can
/// end — twenty answered, hearts gone, or walked away — converges here with a
/// different [QuizRun] shape. Which screen renders is the run's own ending,
/// decided by [QuizResultCubit], never by which route was pushed.
///
/// The run arrives through the route's `extra`. There is no second fetch: the
/// app already holds every answer in memory.
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({required this.run, super.key});

  /// Null when the route was reached without a run — a deep link, or a hot
  /// restart on this screen. That is a real state, so it has a real body.
  final QuizRun? run;

  @override
  Widget build(BuildContext context) {
    final run = this.run;
    if (run == null) return const _MissingRunView();

    return BlocProvider<QuizResultCubit>(
      create: (_) => QuizResultCubit(
        QuizResultRepository(
          QuizResultApi(supabase),
          context.read<AuthRepository>(),
        ),
      )..submit(run, isGuest: context.read<SessionCubit>().isGuest),
      child: BlocBuilder<QuizResultCubit, QuizResultState>(
        builder: (context, state) => switch (state) {
          QuizResultLoading() => const _ResultSpinner(),
          QuizResultError(:final error) => _ResultError(errorCode: error.code),
          QuizResultCompleted() => LevelCompleteScreen(state: state),
          QuizResultFailed() => LevelFailedScreen(state: state),
        },
      ),
    );
  }
}

class _ResultSpinner extends StatelessWidget {
  const _ResultSpinner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.quizoo.s0,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MissingRunView extends StatelessWidget {
  const _MissingRunView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.quizoo.s0,
      body: SafeArea(
        child: Center(
          child: ErrorStateView(
            title: l10n.contentErrorTitle,
            emoji: '🎯',
            message: l10n.contentErrorBody,
            action: ChunkyButton.ghost(
              label: l10n.commonBack,
              onPressed: context.pop,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultError extends StatelessWidget {
  const _ResultError({required this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.quizoo.s0,
      body: SafeArea(
        child: Center(
          child: ErrorStateView(
            title: l10n.contentErrorTitle,
            emoji: '🛰️',
            message: l10n.contentErrorBody,
            errorCode: errorCode,
            action: ChunkyButton.ghost(
              label: l10n.commonBack,
              onPressed: context.pop,
            ),
          ),
        ),
      ),
    );
  }
}

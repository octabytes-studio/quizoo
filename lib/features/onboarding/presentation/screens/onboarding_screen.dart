import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/onboarding/domain/onboarding_slide.dart';
import 'package:quizoo/features/onboarding/presentation/widgets/onboarding_slide_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-02 — the three-card first-run carousel.
///
/// Skippable from card one, which is why "Skip" sits in the top bar rather
/// than appearing only on the last card. Finishing or skipping both hand off
/// to the language picker and mark onboarding seen, so it is shown once per
/// session (see [OnboardingRepository] on why "per session" and not "ever").
///
/// The page index is the textbook case for `setState` under CLAUDE.md §3:
/// purely local, no business meaning, and thrown away when the screen closes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.repository, super.key});

  final OnboardingRepository repository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastSlide => _index == OnboardingSlide.all.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    widget.repository.markOnboardingSeen();
    context.go(AppRoutes.languagePicker);
  }

  void _next() {
    if (_isLastSlide) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppMotion.durationOf(context, AppMotion.slide),
      curve: AppMotion.curveOf(context, AppMotion.slideCurve),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final titles = <OnboardingSlideId, (String, String)>{
      OnboardingSlideId.pick: (
        l10n.onboardingPickTitle,
        l10n.onboardingPickBody,
      ),
      OnboardingSlideId.climb: (
        l10n.onboardingClimbTitle,
        l10n.onboardingClimbBody,
      ),
      OnboardingSlideId.beat: (
        l10n.onboardingBeatTitle,
        l10n.onboardingBeatBody,
      ),
    };

    return Scaffold(
      backgroundColor: quizoo.s0,
      body: SafeArea(
        child: Column(
          children: [
            // `.tb` — the skip affordance is present from card one.
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin.w,
                AppSpacing.xs.h,
                AppSpacing.screenMargin.w,
                AppSpacing.md.h,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GestureDetector(
                  onTap: _finish,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    child: Text(
                      l10n.onboardingSkip,
                      style: textTheme.bodyMedium!.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: quizoo.tx3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: OnboardingSlide.all.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final slide = OnboardingSlide.all[index];
                  final (title, body) = titles[slide.id]!;
                  return OnboardingSlideCard(
                    slide: slide,
                    title: title,
                    body: body,
                  );
                },
              ),
            ),
            _DotsNav(count: OnboardingSlide.all.length, index: _index),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin.w,
                0,
                AppSpacing.screenMargin.w,
                AppSpacing.sm.h + 2.h,
              ),
              child: ChunkyButton(
                label: _isLastSlide
                    ? l10n.onboardingStart
                    : l10n.onboardingNext,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dotsnav` — dots that stretch into a grape bar on the active page.
class _DotsNav extends StatelessWidget {
  const _DotsNav({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var dot = 0; dot < count; dot++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: AnimatedContainer(
                duration: AppMotion.durationOf(context, AppMotion.slide),
                curve: AppMotion.curveOf(context, AppMotion.slideCurve),
                width: (dot == index ? 20 : 7).w,
                height: 7.h,
                decoration: BoxDecoration(
                  color: dot == index ? quizoo.g : quizoo.ln,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

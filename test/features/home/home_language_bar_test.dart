import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/widgets/app_chip.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/home/presentation/bloc/home_language_tabs_cubit.dart';
import 'package:quizoo/features/home/presentation/widgets/home_language_bar.dart';

import '../../support/pump_screen.dart';

class _MockHomeLanguageTabsCubit extends MockCubit<HomeLanguageTabsState>
    implements HomeLanguageTabsCubit {}

class _MockContentLanguageRepository extends Mock
    implements ContentLanguageRepository {}

const _en = LanguageOption(
  code: 'en',
  name: 'English',
  nativeName: 'English',
  isRtl: false,
  sortOrder: 1,
);
const _ur = LanguageOption(
  code: 'ur',
  name: 'Urdu',
  nativeName: 'اردو',
  isRtl: true,
  sortOrder: 2,
);
const _hi = LanguageOption(
  code: 'hi',
  name: 'Hindi',
  nativeName: 'हिन्दी',
  isRtl: false,
  sortOrder: 3,
);

void main() {
  late _MockHomeLanguageTabsCubit tabs;
  late ContentLanguageCubit contentLanguage;

  setUp(() {
    tabs = _MockHomeLanguageTabsCubit();
    final repository = _MockContentLanguageRepository();
    when(() => repository.current).thenReturn('en');
    when(() => repository.select(any())).thenAnswer((_) async {});
    contentLanguage = ContentLanguageCubit(repository);
  });

  Future<void> pumpBar(WidgetTester tester, HomeLanguageTabsState state) {
    when(() => tabs.state).thenReturn(state);
    return tester.pumpScreen(
      BlocProvider<HomeLanguageTabsCubit>.value(
        value: tabs,
        child: const HomeLanguageBar(),
      ),
      contentLanguage: contentLanguage,
    );
  }

  List<AppChip> chips(WidgetTester tester) =>
      tester.widgetList<AppChip>(find.byType(AppChip)).toList();

  group('HomeLanguageBar', () {
    testWidgets('renders one pill per language in order, lead selected', (
      tester,
    ) async {
      await pumpBar(tester, const HomeLanguageTabsLoaded([_en, _ur, _hi]));

      final rendered = chips(tester);
      expect(rendered.map((chip) => chip.label), ['English', 'اردو', 'हिन्दी']);
      expect(rendered.map((chip) => chip.isSelected), [true, false, false]);
    });

    testWidgets('a tap switches language without reordering the row', (
      tester,
    ) async {
      await pumpBar(tester, const HomeLanguageTabsLoaded([_en, _ur, _hi]));

      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(contentLanguage.state.code, 'hi');
      expect(contentLanguage.state.leadCode, 'en');
      final rendered = chips(tester);
      expect(rendered.map((chip) => chip.label), ['English', 'اردو', 'हिन्दी']);
      expect(rendered.map((chip) => chip.isSelected), [false, false, true]);
    });

    testWidgets('hides on error', (tester) async {
      await pumpBar(
        tester,
        const HomeLanguageTabsError(ApiException.network()),
      );

      expect(find.byType(AppChip), findsNothing);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('hides when there is only one language', (tester) async {
      await pumpBar(tester, const HomeLanguageTabsLoaded([_en]));

      expect(find.byType(AppChip), findsNothing);
    });

    testWidgets('shows pill skeletons while loading', (tester) async {
      await pumpBar(tester, const HomeLanguageTabsLoading());
      await tester.pump(AppMotion.skeletonDelay);

      expect(find.byType(SkeletonBox), findsNWidgets(3));
      expect(find.byType(AppChip), findsNothing);

      // Stop the infinite shimmer so the tester can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('spells the language out for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester, const HomeLanguageTabsLoaded([_en, _ur, _hi]));

      expect(find.bySemanticsLabel('Show quizzes in Urdu'), findsOneWidget);
      handle.dispose();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

/// `DeleteAccountScreen` constructs a real `ProfileRepository(ProfileApi
/// (supabase))` inline (matching every other screen post plan-005's
/// migration), reaching the unreachable placeholder client
/// `test/flutter_test_config.dart` sets up — the profile fetch always fails,
/// so there is no loaded `username` left for this screen's "type your
/// username to confirm" gate to compare against. That gate is presentation
/// logic with no dedicated Cubit test file of its own (unlike
/// `quiz_result_cubit_test.dart`'s coverage of `QuizResultCubit`), so this is
/// a real, currently-unfilled coverage gap post-migration — worth a
/// `ProfileCubit`-level widget test with a mocked `ProfileApi` in a follow-up
/// pass, not something this file can still exercise at the full-screen level.
void main() {
  test(
    'placeholder: see the file-level doc comment for why this suite is empty',
    () {},
  );
}

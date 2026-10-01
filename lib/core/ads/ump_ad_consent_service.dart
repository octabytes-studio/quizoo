import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizoo/core/ads/ad_consent_service.dart';

/// The real [AdConsentService], backed by the UMP SDK bundled inside
/// `google_mobile_ads`.
///
/// Which form appears (GDPR, US states, the iOS IDFA explainer) is decided by
/// the messages published in the AdMob console — with none published, no form
/// shows and consent is simply "not required".
class UmpAdConsentService implements AdConsentService {
  @override
  Future<bool> gather() async {
    try {
      final updated = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!updated.isCompleted) updated.complete(true);
        },
        (_) {
          if (!updated.isCompleted) updated.complete(false);
        },
      );
      // A failed update (offline, say) skips the form but still falls through
      // to `canRequestAds()` — consent given in an earlier session counts.
      if (await updated.future) {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      }
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {
      // Nothing to surface — the form simply did not open.
    }
  }
}

import 'package:flutter/widgets.dart';

/// Content languages written right-to-left.
///
/// Mirrors the `languages.is_rtl` column as a small synchronous lookup keyed
/// by code — like `languageFlags` — so the play surfaces can lay a question
/// out the moment it arrives, without an async `languages` fetch first.
const Set<String> rtlLanguageCodes = {'ur', 'ar', 'fa'};

/// The direction text in [languageCode] flows in.
TextDirection textDirectionFor(String languageCode) =>
    rtlLanguageCodes.contains(languageCode)
    ? TextDirection.rtl
    : TextDirection.ltr;

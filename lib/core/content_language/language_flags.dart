/// Flag emoji per language code — the single shared flag lookup for every
/// language surface (onboarding S-03, S-25's sheet, Edit Profile, Home's
/// language pills — plan 021). Cosmetic, not part of the `languages` table,
/// so it stays a small local lookup. No entry falls back to a globe at the
/// call site.
const Map<String, String> languageFlags = {
  'en': '🇬🇧',
  'ur': '🇵🇰',
  'ar': '🇸🇦',
  'hi': '🇮🇳',
  'es': '🇪🇸',
  'fr': '🇫🇷',
};

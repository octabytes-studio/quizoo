import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a request failed, in terms the presentation layer can act on.
enum ApiErrorKind {
  /// No usable connection. Drives the offline state (S-46).
  network,

  /// The server took too long.
  timeout,

  /// The caller is not (or no longer) authenticated.
  unauthorized,

  /// The thing asked for does not exist.
  notFound,

  /// The server broke.
  server,

  /// A response arrived but could not be understood.
  parsing,

  /// Anything else.
  unknown,
}

/// The single exception type the data layer ever throws.
///
/// CLAUDE.md §9: every transport-level failure is mapped to this one type at
/// the boundary, so repositories and Cubits never do ad-hoc `catch
/// (DioException)` handling with feature-specific logic — a Cubit catches
/// [ApiException] and maps it to its own error state, and nothing above the
/// data layer knows what HTTP is.
///
/// It exists in the mock-data phase because that boundary contract is what
/// plans 002–004 write their error paths against; when a real client lands,
/// only the thing that *throws* this changes.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.kind = ApiErrorKind.unknown,
    this.statusCode,
    this.code,
  });

  /// The offline case, which several screens special-case.
  const ApiException.network([
    this.message = 'No connection',
    this.code = 'ERR_NETWORK',
  ]) : kind = ApiErrorKind.network,
       statusCode = null;

  /// Human-readable, for logs — screens show their own copy, not this.
  final String message;

  final ApiErrorKind kind;

  /// The HTTP status, when there was one.
  final int? statusCode;

  /// The machine-readable code an error screen can display
  /// ("ERR_CONTENT_404").
  final String? code;

  bool get isOffline => kind == ApiErrorKind.network;

  @override
  String toString() =>
      'ApiException(${kind.name}${code == null ? '' : ', $code'}): $message';

  /// Maps anything a Supabase call can throw to the one exception type the
  /// rest of the app understands (CLAUDE.md §9's "mapped to a single typed
  /// exception at the boundary", per plan 005's Design overview).
  ///
  /// Every rewritten `*_api.dart` method wraps its body in
  /// `try { ... } catch (e) { throw ApiException.fromSupabase(e); }`.
  factory ApiException.fromSupabase(Object error) {
    if (error is ApiException) return error;

    if (error is AuthException) {
      return ApiException(
        error.message,
        kind: ApiErrorKind.unauthorized,
        code: error.code,
      );
    }

    if (error is PostgrestException) {
      // PGRST116: "no rows" from a .single()/.maybeSingle() that found none —
      // the shape every feature's "content not found" path expects.
      if (error.code == 'PGRST116') {
        return ApiException(
          error.message,
          kind: ApiErrorKind.notFound,
          code: 'ERR_CONTENT_404',
        );
      }
      // A plain `raise exception '<identifier>'` in a function always comes
      // back with SQLSTATE P0001 — Postgres's one generic code for every
      // user-raised exception, regardless of which function raised it or
      // why. The identifier a Cubit actually wants to switch on (e.g.
      // 'out_of_hearts') is the *message*, not that shared code. Only a
      // real Postgres error code (a unique-violation, an RLS denial, ...)
      // is distinctive enough to use as-is.
      return ApiException(
        error.message,
        kind: ApiErrorKind.server,
        code: error.code == 'P0001' ? error.message : error.code,
      );
    }

    if (error is SocketException || error is TimeoutException) {
      return ApiException.network();
    }

    return ApiException(error.toString());
  }
}

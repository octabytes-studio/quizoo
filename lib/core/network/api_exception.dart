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
}

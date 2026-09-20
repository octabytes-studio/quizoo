import 'package:flutter/widgets.dart';

/// Shared [RouteObserver], registered on the root navigator in
/// `app/router.dart`.
///
/// A screen that must refresh when a route pushed on top of it gets popped
/// again (e.g. a level map picking up the progress a just-played quiz wrote)
/// subscribes to this with [RouteAware] and reacts to [RouteAware.didPopNext].
/// `pushReplacement` in the quiz-play flow means that pop never belongs to a
/// future the screen itself awaited, so this is the only reliable signal.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

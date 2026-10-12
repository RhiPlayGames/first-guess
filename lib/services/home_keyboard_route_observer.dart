import 'package:flutter/material.dart';

/// Notifies Home when a game route is popped so stale input focus can be cleared.
final RouteObserver<ModalRoute<dynamic>> homeKeyboardRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

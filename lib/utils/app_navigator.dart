import 'package:flutter/widgets.dart';

/// Global navigator key — used by BaseApiService to redirect to login on
/// session expiry without importing any screen from the service layer.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

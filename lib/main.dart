import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:hackathon_frontend/screens/home/home_screen.dart';
import 'package:hackathon_frontend/services/base_api_service.dart';
import 'package:hackathon_frontend/utils/app_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tzdata.initializeTimeZones();
  final caracas = tz.getLocation('America/Caracas');
  tz.setLocalLocation(caracas);

  await initializeDateFormatting('es', null);
  try {
    if (kIsWeb) {
      await dotenv.load();
    } else {
      await dotenv.load(fileName: '.env');
    }
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Wire session-expiry redirect. Called by BaseApiService on any 401 response.
  BaseApiService.onSessionExpired = () {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<bool> _hasSessionFuture;

  @override
  void initState() {
    super.initState();
    _hasSessionFuture = _hasStoredToken();
  }

  Future<bool> _hasStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.token);
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plancito',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
      ),
      home: FutureBuilder<bool>(
        future: _hasSessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final hasToken = snapshot.data ?? false;
          return hasToken ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

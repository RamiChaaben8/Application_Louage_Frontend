import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/driver_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/driver/driver_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: const ApplicationLouageApp(),
    ),
  );
}

class ApplicationLouageApp extends StatefulWidget {
  const ApplicationLouageApp({super.key});

  @override
  State<ApplicationLouageApp> createState() => _ApplicationLouageAppState();
}

class _ApplicationLouageAppState extends State<ApplicationLouageApp> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.tryRestoreSession();
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Application Louage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: _isChecking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (authProvider.isAuthenticated
              ? (authProvider.isDriver
                  ? const DriverMainScreen()
                  : const MainNavigationScreen())
              : const LoginScreen()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/config/env.dart';
import 'package:circle_app/providers/auth_provider.dart';
import 'package:circle_app/providers/event_provider.dart';
import 'package:circle_app/screens/login_screen.dart';
import 'package:circle_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initEnvironment();
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    publishableKey: Environment.supabaseAnonKey,
  );
  runApp(const CircleApp());
}

class CircleApp extends StatelessWidget {
  const CircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()), // Inyectamos el nuevo módulo globalmente
      ],
      child: MaterialApp(
        title: 'Circle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5),
            primary: const Color(0xFF3F51B5),
            secondary: const Color(0xFFFF9800),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
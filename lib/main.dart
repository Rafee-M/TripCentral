import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For environment variables

import 'package:trip_central/features/auth/ui/auth_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  //Read variables from memory after loaded by pubsec.yaml assets
  final supabaseUrl = dotenv.get('SUPABASE_URL');
  final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripCentral',
      theme: ThemeData(
        // Elegant minimal pastel color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC7B8EA), // Pastel Purple
          primary: const Color(0xFF8E7AB5),
          secondary: const Color(0xFFE4AEC5),
          surface: const Color(0xFFFAFAFA),
          surfaceContainerHighest: const Color(0xFFEFEAF5),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        useMaterial3: true,
        // Font settings natively using built in robust styling parameters
        textTheme: const TextTheme(
           headlineMedium: TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
           headlineSmall: TextStyle(letterSpacing: -0.3, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
           bodyLarge: TextStyle(letterSpacing: 0.1, color: Color(0xFF222222)),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

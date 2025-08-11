import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/customers/splash.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pyudegqeszdngzicuwat.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5dWRlZ3Flc3pkbmd6aWN1d2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4ODg5MzUsImV4cCI6MjA2NTQ2NDkzNX0.Kl0j8M1IyBuatxKTtfLo0ddiPQEd_P2RIA8ZIRgw_bQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    // Define your primary color for the theme
    const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

    return MaterialApp(
      title: 'Tailormate',
      debugShowCheckedModeBanner: false,

      // --- MODERN THEME IMPLEMENTATION ---
      theme: ThemeData(
        // Use Material 3 design
        useMaterial3: true,
        
        // Define the color scheme based on your primary red color
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryRed,
          primary: primaryRed,
          brightness: Brightness.light,
          background: const Color(0xFFF9F9F9), // Soft off-white
        ),


        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // InputDecoration Theme (for TextFields)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryRed, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      
      // The SplashScreen is the correct entry point as it handles role-based routing.
      home: const SplashScreen(),
    );
  }
}
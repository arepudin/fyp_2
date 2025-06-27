import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pyudegqeszdngzicuwat.supabase.co' ,
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5dWRlZ3Flc3pkbmd6aWN1d2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4ODg5MzUsImV4cCI6MjA2NTQ2NDkzNX0.Kl0j8M1IyBuatxKTtfLo0ddiPQEd_P2RIA8ZIRgw_bQ' ,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailormate',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
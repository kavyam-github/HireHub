import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/job_dashboard.dart';

void main() {
  // Boostrap our Flutter application
  runApp(const HireHubApp());
}

/// The root Widget of the HireHub application.
///
/// We use `GetMaterialApp` instead of the standard `MaterialApp` to enable
/// GetX features such as simplified route transitions, state management,
/// and snackbars without needing a BuildContext.
class HireHubApp extends StatelessWidget {
  const HireHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HireHub',
      debugShowCheckedModeBanner: false,
      
      // Define a modern, warm Light Theme for the application
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2563EB), // Professional Blue
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Soft blue-gray
        
        // Customize text themes for readability on light layouts
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1E293B)),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
        ),
        
        // Define theme parameters for standard widgets
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563EB),    // Professional Blue
          secondary: Color(0xFFF97316),  // Warm Orange accent
          surface: Colors.white,         // Card surfaces
        ),
        
        useMaterial3: true,
      ),
      
      // Start with the JobDashboard feed as the home screen
      home: JobDashboard(),
    );
  }
}

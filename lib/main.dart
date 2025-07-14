import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'providers/water_management_provider.dart';
import 'screens/home_screen.dart';

// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(const WaterManagementApp());
}

class WaterManagementApp extends StatelessWidget {
  const WaterManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WaterManagementProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey, // Add the global navigator key
        title: 'Water User Notify',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3), // Blue theme for water
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

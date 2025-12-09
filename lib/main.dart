// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'controllers/app_controller.dart';
import 'services/theme_service.dart'; // Import the new service
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        // 1. Logic Provider
        ChangeNotifierProvider(create: (_) => AppController()),
        // 2. Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: GestureControlApp(cameras: cameras),
    ),
  );
}

class GestureControlApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const GestureControlApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    // Watch the ThemeService for changes
    final themeService = context.watch<ThemeService>();
    
    return MaterialApp(
      title: 'Gesture Controller',
      debugShowCheckedModeBanner: false,
      
      // Use data from ThemeService
      themeMode: themeService.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeService.themeColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: themeService.themeColor,
        brightness: Brightness.dark,
      ),
      
      home: HomeScreen(cameras: cameras),
    );
  }
}
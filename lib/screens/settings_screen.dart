// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/theme_service.dart'; 
import '../controllers/app_controller.dart'; // Import AppController

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final appController = context.watch<AppController>(); // Watch AppController
    
    final List<Color> colors = ThemeService.colorOptions;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          // --- Camera Settings Section (NEW) ---
          _buildSectionHeader(context, "Camera Settings"),
          ListTile(
            title: const Text("Select Camera"),
            trailing: DropdownButton<int>(
              value: appController.selectedCameraIndex,
              underline: Container(), // Remove the default underline
              items: const [
                DropdownMenuItem(value: 0, child: Text("Front Camera (Default)")),
                DropdownMenuItem(value: 1, child: Text("Back Camera")),
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  appController.setSelectedCamera(newValue);
                }
              },
            ),
          ),
          
          const SizedBox(height: 30),
          
          // --- Theme Section (Uses ThemeService) ---
          _buildSectionHeader(context, "Appearance"),
          ListTile(
            // ... (Dark Mode Switch remains the same) ...
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: themeService.themeMode == ThemeMode.dark,
              onChanged: (val) {
                themeService.updateThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Accent Color"),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 15,
              children: colors.map((color) => GestureDetector(
                onTap: () => themeService.updateThemeColor(color), 
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: themeService.themeColor == color 
                        ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) 
                        : null
                  ),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 30),

          // --- Permissions Section ---
          _buildSectionHeader(context, "System Permissions"),
          ListTile(
            title: const Text("Accessibility Service"),
            subtitle: const Text("Required for clicks & swipes"),
            trailing: const Icon(Icons.accessibility_new),
            onTap: () async {
              // Ensure correct import/class usage for AndroidIntentPlus
              final intent = AndroidIntent(action: 'android.settings.ACCESSIBILITY_SETTINGS');
              await intent.launch();
            },
          ),
          ListTile(
            title: const Text("Display Over Apps"),
            subtitle: const Text("Required for cursor overlay"),
            trailing: const Icon(Icons.layers),
            onTap: () async {
              await Permission.systemAlertWindow.request();
            },
          ),
          
          const SizedBox(height: 30),
            _buildSectionHeader(context, "Gesture Customization"),
          _buildGestureTile("Swipe Down", "Exit App"),
          _buildGestureTile("Swipe Left", "Go Back"),
          _buildGestureTile("Swipe Right", "Open Notification Shade"),
          _buildGestureTile("Pinch", "Click"),
          _buildGestureTile("Long Pinch", "Long Press"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildGestureTile(String gesture, String action) {
    return ListTile(
      title: Text(gesture),
      trailing: DropdownButton<String>(
        value: action,
        underline: Container(),
        items: [action].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_) {}, 
      ),
    );
  }
}
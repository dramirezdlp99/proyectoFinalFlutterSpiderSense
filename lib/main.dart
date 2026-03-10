import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/constants.dart';

void main() async {
  // Asegura la inicialización de Flutter antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con las constantes del archivo constants.dart
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const SpiderSenseApp());
}

class SpiderSenseApp extends StatelessWidget {
  const SpiderSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Configuración de temas Light/Dark requerida por el caso de estudio
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.red,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.red,
      ),
      themeMode: ThemeMode.system, // Cambia según la configuración del sistema

      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 100, color: Colors.red),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Spider-Sense',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Initializing AI System...'),
          ],
        ),
      ),
    );
  }
}
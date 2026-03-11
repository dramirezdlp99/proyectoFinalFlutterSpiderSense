import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/constants.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  // 1. Asegura la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Supabase con tus constantes reales
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 3. Inyectamos el controlador de GetX para que esté disponible en toda la app
  Get.put(AuthController());

  runApp(const SpiderSenseApp());
}

class SpiderSenseApp extends StatelessWidget {
  const SpiderSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Configuración de temas Light/Dark
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
      themeMode: ThemeMode.system,

      // Arrancamos con el Splash, el cual nos llevará al Login
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Lógica de navegación: Espera 3 segundos y cambia a la pantalla de Login
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => const LoginScreen());
    });
  }

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
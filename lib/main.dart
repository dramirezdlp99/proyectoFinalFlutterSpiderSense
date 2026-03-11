import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/constants.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

void main() async {
  // 1. Asegura la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 3. Inyectamos el controlador de GetX
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
      
      // CONFIGURACIÓN DE IDIOMAS (i18n)
      // Nota: Asegúrate de que tus archivos JSON en assets/langs/ estén cargados en el pubspec.yaml
      translations: AppTranslations(), // Clase que crearemos a continuación
      locale: Get.deviceLocale, // Detecta el idioma del celular automáticamente
      fallbackLocale: const Locale('en', 'US'), // Idioma por defecto si falla la detección

      // CONFIGURACIÓN DE TEMAS (Light/Dark)
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

      // RUTAS DE LA APLICACIÓN
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
      ],
    );
  }
}

// LÓGICA DE TRADUCCIONES PARA GETX
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // Estas llaves deben coincidir con las que usamos en los controladores y pantallas (.tr)
    'en_US': {
      'splash_init': 'Initializing AI System...',
      // Aquí puedes agregar más si no usas los JSON externos todavía
    },
    'es_ES': {
      'splash_init': 'Inicializando Sistema IA...',
    }
  };
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
    // Navegación usando el sistema de rutas de GetX
    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.red),
            const SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('splash_init'.tr), // Texto traducido
          ],
        ),
      ),
    );
  }
}
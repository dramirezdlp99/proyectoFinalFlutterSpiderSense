import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/constants.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/ia/object_detection_screen.dart'; // IMPORTANTE

class TranslationService extends Translations {
  static Map<String, Map<String, String>> translations = {};

  static Future<void> init() async {
    translations['en_US'] = await _loadJson('en-US');
    translations['es_ES'] = await _loadJson('es-ES');
  }

  static Future<Map<String, String>> _loadJson(String code) async {
    try {
      final String response = await rootBundle.loadString('assets/langs/$code.json');
      final Map<String, dynamic> data = json.decode(response);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint("Error loading translation $code: $e");
      return {};
    }
  }

  @override
  Map<String, Map<String, String>> get keys => translations;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.init();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
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
      translations: TranslationService(), 
      locale: Get.deviceLocale, 
      fallbackLocale: const Locale('en', 'US'),
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
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/ia', page: () => const ObjectDetectionScreen()), // RUTA AGREGADA
      ],
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
            Text(AppConstants.appName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('splash_init'.tr.isEmpty ? 'Initializing AI System...' : 'splash_init'.tr),
          ],
        ),
      ),
    );
  }
}
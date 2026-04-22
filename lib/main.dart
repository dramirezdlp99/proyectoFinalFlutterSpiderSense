import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/localization/translation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'data/models/detection_record.dart';
import 'data/service/history_service.dart';
import 'data/service/sync_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/ia/object_detection_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await dotenv.load(fileName: '.env');
  await TranslationService.init();
  await Hive.initFlutter();
  Hive.registerAdapter(DetectionRecordAdapter());
  await HistoryService().init();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  Get.put(SyncService());
  await SyncService().init();
  Get.put(AuthController());
  final themeCtrl = Get.put(ThemeController());
  await themeCtrl.loadPrefsSync();
  runApp(const SpiderSenseApp());
}

class SpiderSenseApp extends StatefulWidget {
  const SpiderSenseApp({super.key});
  @override
  State<SpiderSenseApp> createState() => _SpiderSenseAppState();
}

class _SpiderSenseAppState extends State<SpiderSenseApp> {
  late ThemeController _ctrl;
  late Locale _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ThemeController>();
    _locale = _ctrl.langCode.value == 'es'
        ? const Locale('es', 'ES')
        : const Locale('en', 'US');
    _themeMode = _ctrl.isDark.value ? ThemeMode.dark : ThemeMode.light;

    // Escuchar cambios con workers de GetX — sin Obx wrapeando GetMaterialApp
    ever(_ctrl.isDark, (bool dark) {
      if (mounted) setState(() {
        _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
      });
    });
    ever(_ctrl.langCode, (String code) {
      if (mounted) setState(() {
        _locale = code == 'es'
            ? const Locale('es', 'ES')
            : const Locale('en', 'US');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      translations: TranslationService(),
      locale: _locale,
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/ia', page: () => const ObjectDetectionScreen()),
        GetPage(name: '/history', page: () => const HistoryScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
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
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    await Future.delayed(const Duration(seconds: 2));
    final s = Supabase.instance.client.auth.currentSession;
    Get.offAllNamed(s != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Stack(children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25, left: -60,
          child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF8B0000).withValues(alpha: 0.3),
                Colors.transparent]))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Spacer(flex: 3),
            const SpiderSenseLogo(size: 80),
            const SizedBox(height: 24),
            const Text('SPIDER-SENSE', style: TextStyle(
              color: Colors.white, fontSize: 36,
              fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('VISUAL AI ASSISTANT', style: TextStyle(
              color: Color(0xFF888888), fontSize: 12,
              letterSpacing: 3, fontWeight: FontWeight.w500)),
            const Spacer(flex: 2),
            const Center(child: CircularProgressIndicator(
                color: Color(0xFF8B0000), strokeWidth: 1.5)),
            const SizedBox(height: 16),
            const Center(child: Text('INITIALIZING SENSORY MATRIX',
                style: TextStyle(color: Color(0xFF555555),
                    fontSize: 11, letterSpacing: 2))),
            const Spacer(),
          ]),
        ),
      ]),
    );
  }
}

// Logo público para reutilizar en login y splash
class SpiderSenseLogo extends StatelessWidget {
  final double size;
  const SpiderSenseLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [BoxShadow(
          color: const Color(0xFF8B0000).withValues(alpha: 0.6),
          blurRadius: 24, spreadRadius: 4)],
      ),
      child: CustomPaint(painter: _LogoPainter(), size: Size(size, size)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final white = Paint()..color = Colors.white
      ..style = PaintingStyle.stroke..strokeWidth = 2;
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dim = Paint()..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (final r in [size.width * 0.38, size.width * 0.28]) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -2.8, 5.6, false, dim);
    }
    final eye = Path()
      ..moveTo(cx - size.width * 0.26, cy)
      ..quadraticBezierTo(cx, cy - size.height * 0.22, cx + size.width * 0.26, cy)
      ..quadraticBezierTo(cx, cy + size.height * 0.22, cx - size.width * 0.26, cy);
    canvas.drawPath(eye, white);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.11, fill);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.04,
        Paint()..color = const Color(0xFF8B0000));
    final line = Paint()..color = Colors.white.withValues(alpha: 0.4)..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - size.height * 0.4),
        Offset(cx, cy - size.height * 0.18), line);
    canvas.drawLine(Offset(cx, cy + size.height * 0.18),
        Offset(cx, cy + size.height * 0.4), line);
  }

  @override
  bool shouldRepaint(_) => false;
}
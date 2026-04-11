import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Views/Widget/liquid_glass.dart';
import 'Views/app_diary_screen.dart';
import 'auth/app_login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseError = await _initializeFirebase();
  runApp(MyApp(firebaseError: firebaseError));
}

Future<String?> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      final options = _firebaseWebOptionsFromEnvironment();
      if (options == null) {
        return 'Thiếu cấu hình Firebase cho bản Web.\n\n'
            'Cách fix nhanh:\n'
            'Chạy app web với --dart-define cho các biến FIREBASE_WEB_*.\n\n'
            'Biến bắt buộc: FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, '
            'FIREBASE_WEB_MESSAGING_SENDER_ID, FIREBASE_WEB_PROJECT_ID.';
      }

      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return null;
  } catch (error) {
    return error.toString();
  }
}

FirebaseOptions? _firebaseWebOptionsFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
  );
  const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }

  const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
  const measurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reedemit Diary',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A7A85),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xCCFFFFFF),
            foregroundColor: const Color(0xFF0F3D44),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: firebaseError == null
          ? const _AuthGate()
          : FirebaseSetupNeededScreen(errorText: firebaseError!),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const AppDiaryScreen();
        }

        return const Login();
      },
    );
  }
}

class FirebaseSetupNeededScreen extends StatelessWidget {
  const FirebaseSetupNeededScreen({super.key, required this.errorText});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thiếu cấu hình Firebase',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kIsWeb
                        ? 'Bạn đang chạy Web. Hãy cấu hình Firebase Web bằng '
                              '`--dart-define`.'
                        : 'Kiểm tra cấu hình trong `lib/firebase_options.dart` '
                              'và bundle id Firebase app.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorText,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
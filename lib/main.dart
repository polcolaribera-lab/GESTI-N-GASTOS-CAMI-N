import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'data/attachment_repository.dart';
import 'data/expense_repository.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const RutaClaraApp());
}

class RutaClaraApp extends StatelessWidget {
  const RutaClaraApp({
    super.key,
    this.authService,
    this.repository,
    this.attachmentRepository,
  });

  final AuthService? authService;
  final ExpenseRepository? repository;
  final AttachmentRepository? attachmentRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaClara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthGate(
        authService: authService ?? FirebaseAuthService(),
        repository: repository,
        attachmentRepository: attachmentRepository,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/expense_repository.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  const RutaClaraApp({super.key, this.repository});

  final ExpenseRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaClara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeShell(repository: repository ?? ExpenseRepository()),
    );
  }
}

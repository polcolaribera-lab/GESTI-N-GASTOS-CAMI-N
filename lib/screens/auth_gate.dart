import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/attachment_repository.dart';
import '../data/expense_repository.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.authService,
    this.repository,
    this.attachmentRepository,
    super.key,
  });

  final AuthService authService;
  final ExpenseRepository? repository;
  final AttachmentRepository? attachmentRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingView();
        }
        if (snapshot.hasError) {
          return const _AuthErrorView();
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginPage(authService: authService);
        }

        return HomeShell(
          key: ValueKey(user.uid),
          repository: repository ?? ExpenseRepository(userId: user.uid),
          attachmentRepository: attachmentRepository ?? AttachmentRepository(),
          user: user,
          onSignOut: authService.signOut,
        );
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _AuthErrorView extends StatelessWidget {
  const _AuthErrorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 46,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo comprobar la sesión',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cierra y vuelve a abrir RutaClara cuando tengas conexión.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

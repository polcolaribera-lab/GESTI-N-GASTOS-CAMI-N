import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.user,
    required this.onSignOut,
    required this.onDeleteAccount,
    super.key,
  });

  final AuthUser user;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Tendrás que volver a introducir tu correo y contraseña para entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onSignOut();
  }

  Future<void> _showPrivacyPolicy(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Política de privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'Ruta Clara utiliza Firebase Authentication para gestionar el acceso con correo o Google. Los gastos y justificantes se guardan localmente en este dispositivo y solo se comparten cuando tú eliges exportarlos. No vendemos tus datos ni usamos publicidad. Puedes eliminar tu cuenta y sus datos desde esta pantalla. Para consultas de privacidad: polcolaribera@gmail.com.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: AppColors.danger,
        ),
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se borrará tu cuenta de acceso, junto con los gastos y justificantes guardados en este dispositivo. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await onDeleteAccount();
    } on AuthFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la cuenta. Inténtalo de nuevo.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('profile'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          sliver: SliverList.list(
            children: [
              const PageHeader(
                title: 'Mi negocio',
                subtitle: 'Configuración del autónomo',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.ink,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transportista autónomo',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Configuración actual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        title: 'Régimen',
                        value: 'Autónomo',
                      ),
                      Divider(height: 1),
                      _InfoRow(
                        icon: Icons.flag_outlined,
                        title: 'País fiscal',
                        value: 'España',
                      ),
                      Divider(height: 1),
                      _InfoRow(
                        icon: Icons.track_changes_rounded,
                        title: 'Límite mensual',
                        value: '2.500 €',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Tu sesión', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuenta conectada',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Privacidad', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.phonelink_lock_rounded,
                          color: AppColors.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tus datos se quedan contigo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tu cuenta se protege con Firebase. Los gastos y justificantes se guardan únicamente en este dispositivo y separados por cuenta.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showPrivacyPolicy(context),
                icon: const Icon(Icons.policy_outlined),
                label: const Text('Leer la política de privacidad'),
              ),
              const SizedBox(height: 28),
              Text(
                'Próximas funciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _RoadmapRow(
                        icon: Icons.document_scanner_outlined,
                        title: 'Escanear tickets',
                      ),
                      Divider(height: 1),
                      _RoadmapRow(
                        icon: Icons.file_download_outlined,
                        title: 'Informes anuales comparativos',
                      ),
                      Divider(height: 1),
                      _RoadmapRow(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Copia de seguridad',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _confirmDeleteAccount(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Eliminar mi cuenta'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Ruta Clara · Versión 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 13),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 21),
          const SizedBox(width: 13),
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pronto',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

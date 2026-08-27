import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _changeMode(bool register) {
    if (_loading || _isRegistering == register) return;
    setState(() {
      _isRegistering = register;
      _errorMessage = null;
      _confirmationController.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegistering) {
        await widget.authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ha ocurrido un error. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signInWithGoogle();
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo iniciar sesión con Google.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _googleLoading = false;
        });
      }
    }
  }

  Future<void> _showPasswordReset() async {
    final resetController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    var sending = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !sending,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendReset() async {
            if (!(formKey.currentState?.validate() ?? false)) return;
            setDialogState(() {
              sending = true;
              dialogError = null;
            });
            try {
              await widget.authService.sendPasswordResetEmail(
                resetController.text,
              );
              if (!mounted || !dialogContext.mounted) return;
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Te hemos enviado un enlace para recuperarla.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } on AuthFailure catch (error) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                sending = false;
                dialogError = error.message;
              });
            } catch (_) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                sending = false;
                dialogError = 'No se pudo enviar el correo.';
              });
            }
          }

          return AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escribe tu correo y recibirás un enlace para crear una contraseña nueva.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !sending,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => sendReset(),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: sending ? null : sendReset,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enviar enlace'),
              ),
            ],
          );
        },
      ),
    );
    resetController.dispose();
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Introduce un correo válido';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isRegistering
                                      ? 'Crea tu cuenta'
                                      : 'Bienvenido de nuevo',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isRegistering
                                      ? 'Empieza a ordenar los gastos de tu actividad.'
                                      : 'Accede a los gastos de tu negocio.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 22),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: false,
                                      label: Text('Iniciar sesión'),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      label: Text('Crear cuenta'),
                                    ),
                                  ],
                                  selected: {_isRegistering},
                                  onSelectionChanged: (selection) {
                                    _changeMode(selection.first);
                                  },
                                  showSelectedIcon: false,
                                ),
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : _signInWithGoogle,
                                  icon: _googleLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.3,
                                          ),
                                        )
                                      : const _GoogleMark(),
                                  label: const Text('Continuar con Google'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'o usa tu correo',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !_loading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Correo electrónico',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !_loading,
                                  obscureText: _obscurePassword,
                                  textInputAction: _isRegistering
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  autofillHints: [
                                    _isRegistering
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Mostrar contraseña'
                                          : 'Ocultar contraseña',
                                      onPressed: () => setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      }),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                  onFieldSubmitted: _isRegistering
                                      ? null
                                      : (_) => _submit(),
                                ),
                                if (_isRegistering) ...[
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _confirmationController,
                                    enabled: !_loading,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Repite la contraseña',
                                      prefixIcon: Icon(
                                        Icons.lock_reset_rounded,
                                      ),
                                    ),
                                    validator: _validateConfirmation,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                ],
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 20,
                                          color: AppColors.danger,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: AppColors.danger,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (!_isRegistering)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : _showPasswordReset,
                                      child: const Text(
                                        '¿Has olvidado la contraseña?',
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isRegistering
                                              ? 'Crear mi cuenta'
                                              : 'Entrar en Ruta Clara',
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Acceso protegido por Firebase',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE3E7EC)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 15),
        Text('Ruta Clara', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          'Tus gastos de ruta, bajo control',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5F0), AppColors.surface, Color(0xFFFFF4E4)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _Glow(color: AppColors.accent, size: 220),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _Glow(color: AppColors.primary, size: 260),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

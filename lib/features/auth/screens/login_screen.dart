import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_footer.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .login(_usernameController.text.trim(), _passwordController.text);

      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      } else if (mounted) {
        await AppDialog.error(
          context,
          title: 'Masuk gagal',
          message:
              ref.read(authProvider).error ??
              'Nama pengguna atau kata sandi tidak valid.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.pendingSessionTerminationBanner || next.error == null) return;
      final msg = next.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(authProvider.notifier).clearSessionTerminationBanner();
        AppToast.show(
          context,
          msg,
          type: AppNoticeType.warning,
          duration: const Duration(seconds: 8),
        );
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/ic_foreground.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.gapXl,

                  AppTextField(
                    controller: _usernameController,
                    label: 'Nama pengguna',
                    required: true,
                    prefixIcon: Icons.person,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan nama pengguna Anda';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapMd,

                  AppTextField(
                    controller: _passwordController,
                    label: 'Kata sandi',
                    required: true,
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan kata sandi Anda';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapXl,

                  AppButton(
                    label: 'Masuk',
                    onPressed: authState.isLoading ? null : _handleLogin,
                    loading: authState.isLoading,
                    fullWidth: true,
                  ),
                  AppSpacing.gapXl,
                  const Center(child: AppFooter()),
                  AppSpacing.gapMd,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

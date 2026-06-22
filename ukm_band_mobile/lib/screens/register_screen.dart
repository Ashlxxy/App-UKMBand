import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_stage.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainShell()),
        (route) => false,
      );
    } else {
      final message =
          authProvider.errorMessage ?? 'Registrasi gagal. Silakan coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthStage(
      appBarTitle: 'Daftar Sekarang',
      title: 'Buat Akun Baru',
      subtitle: 'Gabung ke ruang musik komunitas dan simpan aktivitasmu.',
      icon: Icons.person_add_alt_1_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kata sandi tidak boleh kosong';
                }
                if (value.length < 8) {
                  return 'Kata sandi minimal 8 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordConfirmationController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi kata sandi tidak boleh kosong';
                }
                if (value != _passwordController.text) {
                  return 'Konfirmasi kata sandi tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: isLoading ? null : _register,
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(isLoading ? 'Mendaftarkan...' : 'Daftar'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Gunakan minimal 8 karakter untuk kata sandi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_trainer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_trainer_app/core/theme/app_colors.dart';
import 'package:gym_trainer_app/shared/widgets/gym_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _autoBiometricsAttempted = false; // Flag to prevent infinite biometric loops on Android pause/resume lifecycle

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _tryBiometricLogin());
  }

  Future<void> _tryBiometricLogin() async {
    if (_autoBiometricsAttempted) return;
    
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.authenticated) {
      return;
    }
    
    _autoBiometricsAttempted = true;

    final storage = ref.read(secureStorageProvider);
    final bioEnabled = await storage.isBiometricEnabled();
    final email = await storage.getUserEmail();
    final password = await storage.getPassword();
    
    if (email != null) {
      _emailController.text = email;
      if (password != null) {
        _passwordController.text = password;
      }
    }

    if (bioEnabled && email != null && password != null) {
      await ref.read(authProvider.notifier).loginWithBiometrics();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(next.error!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    });

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF15151B),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15151B), Color(0xFF0F0F12)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF6B00).withOpacity(0.12),
                          border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.2)),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'GYM TRAINER',
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tu evolución inteligente empieza aquí',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF19191F),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (!value.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF19191F),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: authState.status == AuthStatus.loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authState.status == AuthStatus.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Text(
                                  'ENTRAR',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),
                      FutureBuilder<bool>(
                        future: ref.read(secureStorageProvider).isBiometricEnabled(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00E5FF),
                                ),
                                onPressed: () => ref.read(authProvider.notifier).loginWithBiometrics(),
                                icon: const Icon(Icons.fingerprint_rounded, size: 28),
                                label: const Text(
                                  'Entrar con Huella / Cara',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: Colors.white54),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/register'),
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
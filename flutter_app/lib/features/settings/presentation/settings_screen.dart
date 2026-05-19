import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_trainer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_trainer_app/shared/widgets/gym_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _openaiKeyController;
  late TextEditingController _deepseekKeyController;
  late TextEditingController _minimaxKeyController;
  String? _selectedProvider;
  bool _isSaving = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _openaiKeyController = TextEditingController(text: user?.openaiApiKey ?? '');
    _deepseekKeyController = TextEditingController(text: user?.deepseekApiKey ?? '');
    _minimaxKeyController = TextEditingController(text: user?.minimaxApiKey ?? '');
    _selectedProvider = user?.proveedorIaPreferido;
    
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final enabled = await ref.read(secureStorageProvider).isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
    _deepseekKeyController.dispose();
    _minimaxKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateSettings({
        'openai_api_key': _openaiKeyController.text.trim(),
        'deepseek_api_key': _deepseekKeyController.text.trim(),
        'minimax_api_key': _minimaxKeyController.text.trim(),
        'proveedor_ia_preferido': _selectedProvider,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E5FF),
            content: Text('Configuración guardada correctamente', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E24),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF15151B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Configuración',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          backgroundColor: const Color(0xFF0F0F12),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Configuración de IA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige tu proveedor preferido o añade llaves de API personalizadas para generar rutinas.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 16),
            GymCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Proveedor de IA Preferido',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedProvider,
                      dropdownColor: const Color(0xFF15151B),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Auto (Prioridad de Servidor)', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'deepseek',
                          child: Text('🥇 DeepSeek (deepseek-chat)', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'minimax',
                          child: Text('🥈 MiniMax 2.7 (minimax-text-01)', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'openai',
                          child: Text('🥉 OpenAI (gpt-4o)', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'gemini',
                          child: Text('🍀 Gemini (gemini-2.0-flash)', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedProvider = val),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DeepSeek API Key',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deepseekKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'sk-...',
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'MiniMax API Key',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _minimaxKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Clave MiniMax...',
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OpenAI API Key',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _openaiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'sk-...',
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                      child: _isSaving 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Guardar Ajustes de IA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seguridad y Acceso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Protege tu acceso rápido al gimnasio a través de la autenticación biométrica.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 16),
            GymCard(
              child: SwitchListTile(
                title: const Text('Iniciar sesión con huella / cara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Utiliza la biometría segura de tu móvil para entrar sin volver a escribir la clave.', style: TextStyle(fontSize: 11)),
                value: _biometricEnabled,
                activeColor: const Color(0xFFFF6B00),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onChanged: (val) async {
                  final supported = await ref.read(authProvider.notifier).deviceSupportsBiometrics();
                  if (!supported) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFFFF3366),
                          content: Text('Tu móvil no soporta o no tiene configurado el desbloqueo facial/huella.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                    return;
                  }
                  setState(() => _biometricEnabled = val);
                  await ref.read(secureStorageProvider).saveBiometricEnabled(val);
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Información de la Cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GymCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Email', ref.watch(authProvider).user?.email ?? '-'),
                    const Divider(color: Colors.white10),
                    _buildInfoRow('Nombre', ref.watch(authProvider).user?.nombre ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Servidor y Conectividad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configura los datos del servidor central de producción.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 16),
            GymCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoRow('Endpoint Activo', ref.watch(apiUrlProvider) ?? 'Ninguno'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16161E),
                        side: const BorderSide(color: Colors.orange, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () async {
                        // Limpiar URL del servidor
                        final storage = ref.read(secureStorageProvider);
                        await storage.saveApiBaseUrl('');
                        await ref.read(authProvider.notifier).logout();
                        
                        // Limpiar el provider de la API
                        ref.read(apiUrlProvider.notifier).state = null;
                      },
                      child: const Text(
                        'Desvincular y Cambiar Servidor 🌐',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

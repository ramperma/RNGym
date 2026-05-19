import 'package:flutter/material.dart';

import '../data/profile_api.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ProfileApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  UserProfile? _profile;
  AiStatus? _aiStatus;
  String? _selectedSex;
  String? _selectedGoal;
  bool _aiPersonalizationEnabled = true;

  static const _sexOptions = {
    'masculino': 'Masculino',
    'femenino': 'Femenino',
    'otro': 'Otro',
    'prefiero_no_decir': 'Prefiero no decirlo',
  };

  static const _goalOptions = {
    'perder_grasa': 'Perder grasa',
    'ganar_musculo': 'Ganar músculo',
    'mantener': 'Mantener',
    'rendimiento': 'Rendimiento',
    'salud_general': 'Salud general',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _injuriesController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.fetchProfile(), _api.fetchAiStatus()]);
      final profile = results[0] as UserProfile;
      final aiStatus = results[1] as AiStatus;
      _applyProfile(profile);
      setState(() { _profile = profile; _aiStatus = aiStatus; _loading = false; });
    } catch (error) {
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  void _applyProfile(UserProfile profile) {
    _nameController.text = profile.displayName;
    _ageController.text = profile.age?.toString() ?? '';
    _weightController.text = profile.weightKg?.toString() ?? '';
    _heightController.text = profile.heightCm?.toString() ?? '';
    _injuriesController.text = profile.injuries;
    _medicalNotesController.text = profile.medicalNotes;
    _selectedSex = profile.sex;
    _selectedGoal = profile.goal;
    _aiPersonalizationEnabled = profile.aiPersonalizationEnabled;
  }

  int? _parseInt(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  double? _parseDouble(TextEditingController c) {
    final v = c.text.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final saved = await _api.saveProfile(UserProfileUpdate(
        displayName: _nameController.text.trim(),
        age: _parseInt(_ageController),
        weightKg: _parseDouble(_weightController),
        heightCm: _parseInt(_heightController),
        sex: _selectedSex,
        goal: _selectedGoal,
        injuries: _injuriesController.text.trim(),
        medicalNotes: _medicalNotesController.text.trim(),
        aiPersonalizationEnabled: _aiPersonalizationEnabled,
      ));
      final aiStatus = await _api.fetchAiStatus();
      _applyProfile(saved);
      setState(() { _profile = saved; _aiStatus = aiStatus; _saving = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente.')),
      );
    } catch (error) {
      setState(() { _error = error.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _profile == null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          _SectionHeader(
            icon: Icons.person,
            title: 'Mi perfil',
            subtitle: 'Datos que personalizan tus rutinas y recomendaciones de IA.',
          ),
          const SizedBox(height: 14),
          if (_aiStatus != null) ...[
            _AiStatusCard(status: _aiStatus!),
            const SizedBox(height: 14),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormSectionTitle('Información básica'),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre visible',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Edad',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 13 || n > 100) return '13-100';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedSex,
                          decoration: const InputDecoration(labelText: 'Sexo'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('No indicado')),
                            ..._sexOptions.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                          ],
                          onChanged: (v) => setState(() => _selectedSex = v),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.monitor_weight_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(v.trim().replaceAll(',', '.'));
                            if (n == null || n <= 0 || n > 400) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Altura (cm)',
                            prefixIcon: Icon(Icons.height_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 100 || n > 250) return '100-250';
                            return null;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _FormSectionTitle('Objetivo'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedGoal,
                      decoration: const InputDecoration(
                        labelText: 'Objetivo principal',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Sin definir todavía')),
                        ..._goalOptions.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                      ],
                      onChanged: (v) => setState(() => _selectedGoal = v),
                    ),
                    const SizedBox(height: 20),
                    _FormSectionTitle('Salud'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _injuriesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Lesiones o problemas articulares',
                        hintText: 'Ej: hombro derecho, rodilla, lumbar…',
                        prefixIcon: Icon(Icons.healing_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicalNotesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Medicación u observaciones',
                        prefixIcon: Icon(Icons.medical_information_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AiToggleTile(
                      value: _aiPersonalizationEnabled,
                      onChanged: (v) => setState(() => _aiPersonalizationEnabled = v),
                    ),
                    if (_profile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Actualizado: ${_fmt(_profile!.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Componentes privados ────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F2747), Color(0xFF1E4F8A)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        )),
      ],
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String text;
  const _FormSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.9, color: const Color(0xFF7A8FA6)),
    );
  }
}

class _AiToggleTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AiToggleTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6F0)),
      ),
      child: SwitchListTile(
        value: value,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text('Personalización con IA', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          'El backend adaptará recomendaciones con tu perfil cuando haya proveedor IA activo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _AiStatusCard extends StatelessWidget {
  final AiStatus status;
  const _AiStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final ready = status.enabled;
    final accent = ready ? const Color(0xFF0D7A5F) : const Color(0xFFB45309);
    final bg = ready ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final border = ready ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.smart_toy_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ready ? 'IA conectada' : 'IA pendiente de configurar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accent)),
              const SizedBox(height: 3),
              Text('Proveedor: ${status.provider}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                status.personalizationReady
                    ? 'Perfil con datos suficientes para personalizar.'
                    : 'Completa el perfil para mejorar las recomendaciones.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Color(0xFF7A8FA6)),
            const SizedBox(height: 14),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

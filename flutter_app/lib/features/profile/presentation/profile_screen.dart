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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchProfile(),
        _api.fetchAiStatus(),
      ]);
      final profile = results[0] as UserProfile;
      final aiStatus = results[1] as AiStatus;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _aiStatus = aiStatus;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
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

  int? _parseInt(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  double? _parseDouble(TextEditingController controller) {
    final value = controller.text.trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final savedProfile = await _api.saveProfile(
        UserProfileUpdate(
          displayName: _nameController.text.trim(),
          age: _parseInt(_ageController),
          weightKg: _parseDouble(_weightController),
          heightCm: _parseInt(_heightController),
          sex: _selectedSex,
          goal: _selectedGoal,
          injuries: _injuriesController.text.trim(),
          medicalNotes: _medicalNotesController.text.trim(),
          aiPersonalizationEnabled: _aiPersonalizationEnabled,
        ),
      );
      final aiStatus = await _api.fetchAiStatus();
      _applyProfile(savedProfile);
      setState(() {
        _profile = savedProfile;
        _aiStatus = aiStatus;
        _saving = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente.')),
      );
    } catch (error) {
      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Perfil y personalización',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Estos datos preparan el terreno para ajustar rutinas y nutrición desde el backend, sin guardar claves de IA en el cliente.',
          ),
          const SizedBox(height: 16),
          if (_aiStatus != null) _AiStatusCard(status: _aiStatus!),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre visible'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration:
                                const InputDecoration(labelText: 'Edad'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null ||
                                  parsed < 13 ||
                                  parsed > 100) {
                                return '13-100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration:
                                const InputDecoration(labelText: 'Peso (kg)'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = double.tryParse(
                                  value.trim().replaceAll(',', '.'));
                              if (parsed == null ||
                                  parsed <= 0 ||
                                  parsed > 400) {
                                return 'Peso inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration:
                                const InputDecoration(labelText: 'Altura (cm)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null ||
                                  parsed < 100 ||
                                  parsed > 250) {
                                return '100-250';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedSex,
                            decoration:
                                const InputDecoration(labelText: 'Sexo'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No indicado'),
                              ),
                              ..._sexOptions.entries.map(
                                (entry) => DropdownMenuItem<String?>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSex = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedGoal,
                      decoration: const InputDecoration(
                          labelText: 'Objetivo principal'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin definir todavía'),
                        ),
                        ..._goalOptions.entries.map(
                          (entry) => DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGoal = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _injuriesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Lesiones o problemas articulares',
                        hintText: 'Ej: hombro derecho, rodilla, lumbar...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicalNotesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Enfermedades, medicación u observaciones',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _aiPersonalizationEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permitir personalización con IA'),
                      subtitle: const Text(
                        'El backend podrá usar este perfil para adaptar recomendaciones cuando el proveedor esté disponible.',
                      ),
                      onChanged: (value) {
                        setState(() => _aiPersonalizationEnabled = value);
                      },
                    ),
                    if (_profile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Última actualización: ${_profile!.updatedAt.day.toString().padLeft(2, '0')}/${_profile!.updatedAt.month.toString().padLeft(2, '0')} ${_profile!.updatedAt.hour.toString().padLeft(2, '0')}:${_profile!.updatedAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label:
                            Text(_saving ? 'Guardando...' : 'Guardar perfil'),
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
}

class _AiStatusCard extends StatelessWidget {
  final AiStatus status;

  const _AiStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.enabled ? Colors.green : Colors.orange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estado IA: ${status.enabled ? 'conectada' : 'pendiente de configurar'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Proveedor backend: ${status.provider}'),
            Text(
              status.personalizationReady
                  ? 'El perfil ya tiene datos útiles para personalización.'
                  : 'Faltan más datos de perfil para personalizar mejor.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Las credenciales sensibles se quedan en backend. La app solo consulta el estado y envía datos de perfil.',
            ),
          ],
        ),
      ),
    );
  }
}

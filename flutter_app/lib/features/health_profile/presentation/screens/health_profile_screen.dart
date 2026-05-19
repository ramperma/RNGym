import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_profile_provider.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProfileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Salud'),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        label: Text(state.perfil == null ? 'Crear perfil' : 'Editar perfil'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBody(HealthProfileState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return Center(child: Text('Error: ${state.error}'));

    final perfil = state.perfil;
    if (perfil == null) {
      return const Center(child: Text('No tienes perfil de salud aún'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard('Datos corporales', [
          _buildRow('Altura', '${perfil.alturaCm ?? '-'} cm'),
          _buildRow('Peso actual', '${perfil.pesoActualKg ?? '-'} kg'),
          _buildRow('Peso deseado', '${perfil.pesoDeseadoKg ?? '-'} kg'),
          _buildRow('% Grasa', perfil.porcentajeGrasa != null ? '${perfil.porcentajeGrasa}%' : '-'),
          _buildRow('% Músculo', perfil.porcentajeMusculo != null ? '${perfil.porcentajeMusculo}%' : '-'),
        ]),
        const SizedBox(height: 16),
        _buildCard('Objetivo', [
          _buildRow('Objetivo principal', perfil.objetivoPrincipal ?? '-'),
          _buildRow('Detalle', perfil.objetivoDetalle ?? '-'),
        ]),
        const SizedBox(height: 16),
        _buildCard('Salud', [
          _buildRow('Lesiones', perfil.lesiones?.join(', ') ?? 'Ninguna'),
          _buildRow('Condiciones médicas', perfil.condicionesMedicas?.join(', ') ?? 'Ninguna'),
          _buildRow('Alergias', perfil.alergias?.join(', ') ?? 'Ninguna'),
          _buildRow('Medicamentos', perfil.medicamentos?.join(', ') ?? 'Ninguno'),
        ]),
        const SizedBox(height: 16),
        _buildCard('Consentimiento', [
          _buildRow('Consentimiento salud', perfil.consentimientoSalud ? 'Sí' : 'No'),
          if (perfil.fechaNacimiento != null)
            _buildRow('Fecha nacimiento', '${perfil.fechaNacimiento!.day}/${perfil.fechaNacimiento!.month}/${perfil.fechaNacimiento!.year}'),
        ]),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _HealthProfileForm()),
    );
  }
}

class _HealthProfileForm extends ConsumerStatefulWidget {
  const _HealthProfileForm();

  @override
  ConsumerState<_HealthProfileForm> createState() => _HealthProfileFormState();
}

class _HealthProfileFormState extends ConsumerState<_HealthProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _alturaController = TextEditingController();
  final _pesoActualController = TextEditingController();
  final _pesoDeseadoController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _objetivoDetalleController = TextEditingController();

  final List<String> _lesionesDisponibles = [
    '🤕 Hombro operado / dolor',
    '🦵 Rodilla (Meniscos / ligamento)',
    '💥 Espalda baja / lumbar',
    '🦶 Tobillo / pie',
    '💪 Codo / muñeca',
  ];
  final List<String> _lesionesSeleccionadas = [];

  final List<String> _condicionesDisponibles = [
    '❤️ Hipertensión',
    '🩺 Asma / respiratorio',
    '🩹 Diabetes',
    '🦴 Hernia discal',
  ];
  final List<String> _condicionesSeleccionadas = [];

  @override
  void initState() {
    super.initState();
    final perfil = ref.read(healthProfileProvider).perfil;
    if (perfil != null) {
      _alturaController.text = perfil.alturaCm?.toString() ?? '';
      _pesoActualController.text = perfil.pesoActualKg?.toString() ?? '';
      _pesoDeseadoController.text = perfil.pesoDeseadoKg?.toString() ?? '';
      _objetivoController.text = perfil.objetivoPrincipal ?? '';
      _objetivoDetalleController.text = perfil.objetivoDetalle ?? '';
      if (perfil.lesiones != null) {
        _lesionesSeleccionadas.addAll(perfil.lesiones!);
      }
      if (perfil.condicionesMedicas != null) {
        _condicionesSeleccionadas.addAll(perfil.condicionesMedicas!);
      }
    }
  }

  @override
  void dispose() {
    _alturaController.dispose();
    _pesoActualController.dispose();
    _pesoDeseadoController.dispose();
    _objetivoController.dispose();
    _objetivoDetalleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(healthProfileProvider.notifier).saveProfile({
        'altura_cm': double.tryParse(_alturaController.text),
        'peso_actual_kg': double.tryParse(_pesoActualController.text),
        'peso_deseado_kg': double.tryParse(_pesoDeseadoController.text),
        'objetivo_principal': _objetivoController.text.isEmpty ? null : _objetivoController.text,
        'objetivo_detalle': _objetivoDetalleController.text.isEmpty ? null : _objetivoDetalleController.text,
        'lesiones': _lesionesSeleccionadas,
        'condiciones_medicas': _condicionesSeleccionadas,
        'consentimiento_salud': true,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil de salud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _alturaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoActualController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso actual (kg)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoDeseadoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso deseado (kg)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _objetivoController,
                decoration: const InputDecoration(
                  labelText: 'Objetivo principal',
                  hintText: 'ej: perder grasa, ganar músculo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _objetivoDetalleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detalles del objetivo / preferencias',
                  hintText: 'ej: ganar fuerza protegiendo rodillas y priorizando poleas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Lesiones o limitaciones articulares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _lesionesDisponibles.map((lesion) {
                  final isSelected = _lesionesSeleccionadas.contains(lesion);
                  return FilterChip(
                    label: Text(lesion),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF6B00),
                    backgroundColor: const Color(0xFF0F0F12),
                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _lesionesSeleccionadas.add(lesion);
                        } else {
                          _lesionesSeleccionadas.remove(lesion);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Condiciones médicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _condicionesDisponibles.map((cond) {
                  final isSelected = _condicionesSeleccionadas.contains(cond);
                  return FilterChip(
                    label: Text(cond),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF6B00),
                    backgroundColor: const Color(0xFF0F0F12),
                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _condicionesSeleccionadas.add(cond);
                        } else {
                          _condicionesSeleccionadas.remove(cond);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar perfil de salud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyRecordsProvider = StateNotifierProvider<DailyRecordsNotifier, DailyRecordsState>((ref) {
  return DailyRecordsNotifier();
});

class DailyRecordsState {
  final bool isLoading;
  final Map<DateTime, Map<String, dynamic>> records;
  final String? error;

  const DailyRecordsState({this.isLoading = false, this.records = const {}, this.error});

  DailyRecordsState copyWith({bool? isLoading, Map<DateTime, Map<String, dynamic>>? records, String? error}) {
    return DailyRecordsState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      error: error,
    );
  }
}

class DailyRecordsNotifier extends StateNotifier<DailyRecordsState> {
  DailyRecordsNotifier() : super(const DailyRecordsState());

  Future<void> loadRecord(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final record = {
        'fecha': date,
        'peso_kg': null,
        'horas_sueño': null,
        'nivel_energia': null,
        'nivel_estres': null,
        'ejercicios_realizados': null,
        'minutos_entreno': null,
        'notas': null,
      };
      final newRecords = Map<DateTime, Map<String, dynamic>>.from(state.records);
      newRecords[date] = record;
      state = state.copyWith(isLoading: false, records: newRecords);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class DailyRecordsScreen extends ConsumerStatefulWidget {
  const DailyRecordsScreen({super.key});

  @override
  ConsumerState<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends ConsumerState<DailyRecordsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordsProvider);
    final record = state.records[_selectedDate];

    return Scaffold(
      appBar: AppBar(title: const Text('Registro Diario')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
              ref.read(dailyRecordsProvider.notifier).loadRecord(date);
            },
          ),
          const Divider(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registro del ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text('Peso: ${record?['peso_kg'] ?? '-'} kg'),
                        Text('Sueño: ${record?['horas_sueño'] ?? '-'} h'),
                        Text('Energía: ${record?['nivel_energia'] ?? '-'}/10'),
                        Text('Estrés: ${record?['nivel_estres'] ?? '-'}/10'),
                        Text('Minutos entreno: ${record?['minutos_entreno'] ?? '-'}'),
                        Text('Ejercicios: ${record?['ejercicios_realizados'] ?? '-'}'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
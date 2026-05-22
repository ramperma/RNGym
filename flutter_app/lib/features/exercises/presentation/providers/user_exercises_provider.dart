import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/user_exercise_api.dart';
import '../../domain/user_exercise.dart';

final userExerciseApiProvider = Provider((ref) {
  return UserExerciseApi(ref.watch(apiClientProvider));
});

class UserExercisesState {
  final List<UserExercise> exercises;
  final bool isLoading;
  final String? error;

  const UserExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  UserExercisesState copyWith({
    List<UserExercise>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return UserExercisesState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserExercisesNotifier extends StateNotifier<UserExercisesState> {
  final UserExerciseApi _api;

  UserExercisesNotifier(this._api) : super(const UserExercisesState());

  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exercises = await _api.listExercises();
      state = state.copyWith(exercises: exercises, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<UserExercise?> createExercise(Map<String, dynamic> data) async {
    try {
      final exercise = await _api.createExercise(data);
      await loadExercises();
      return exercise;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<UserExercise?> updateExercise(String id, Map<String, dynamic> data) async {
    try {
      final exercise = await _api.updateExercise(id, data);
      await loadExercises();
      return exercise;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteExercise(String id) async {
    try {
      await _api.deleteExercise(id);
      await loadExercises();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final userExercisesProvider =
    StateNotifierProvider<UserExercisesNotifier, UserExercisesState>((ref) {
  final api = ref.watch(userExerciseApiProvider);
  return UserExercisesNotifier(api);
});

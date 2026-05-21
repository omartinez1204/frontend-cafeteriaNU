import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/dio_provider.dart';

/// Provider para buscar alumnos (becados) desde la caja
final studentSearchProvider =
    StateNotifierProvider<StudentSearchNotifier, StudentSearchState>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return StudentSearchNotifier(dio);
});

class StudentSearchState {
  final List<UserModel> students;
  final bool isLoading;
  final String? error;
  final String query;

  const StudentSearchState({
    this.students = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  StudentSearchState copyWith({
    List<UserModel>? students,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return StudentSearchState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }
}

class StudentSearchNotifier extends StateNotifier<StudentSearchState> {
  final Dio _dio;

  StudentSearchNotifier(this._dio) : super(const StudentSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const StudentSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null, query: query);

    try {
      final response = await _dio.get('/users/search-students', queryParameters: {'q': query});
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data'] as List
          : response.data as List;

      final students = data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = StudentSearchState(
        students: students,
        isLoading: false,
        query: query,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar alumnos: $e',
      );
    }
  }

  void clear() {
    state = const StudentSearchState();
  }
}

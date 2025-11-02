import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'debug_event.dart';
import 'debug_state.dart';

class DebugBloc extends Bloc<DebugEvent, DebugState> {
  final StudentOperationsUseCases useCases;

  DebugBloc(this.useCases) : super(DebugState()) {
    on<LoadDebugDataEvent>(_onLoadDebugData);
  }

  Future<void> _onLoadDebugData(
    LoadDebugDataEvent event,
    Emitter<DebugState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DebugStatus.loading));
      final students = await useCases.getAllStudents();
      final rooms = await useCases.getAllRooms();
      final foods = await useCases.getAllFood();
      final records = await useCases.getAllStudentFoodRecords();

      final List<Map<String, dynamic>> resolvedRecords = [];
      for (var record in records) {
        final student = students.firstWhere((s) => s.id == record.studentId);
        final food = foods.firstWhere((f) => f.id == record.foodId);
        resolvedRecords.add({
          'studentName': student.name,
          'foodName': food.name,
          'date': record.date,
        });
      }

      emit(
        state.copyWith(
          status: DebugStatus.success,
          students: students,
          rooms: rooms,
          foods: foods,
          records: resolvedRecords,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: DebugStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}

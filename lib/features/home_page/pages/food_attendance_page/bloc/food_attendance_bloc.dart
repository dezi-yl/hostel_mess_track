import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:bloc/bloc.dart';
import 'package:hostel_mess_2/core/domain/entities/food_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'package:meta/meta.dart';

part 'food_attendance_event.dart';
part 'food_attendance_state.dart';

class FoodAttendanceBloc
    extends Bloc<FoodAttendanceEvent, FoodAttendanceState> {
  final StudentOperationsUseCases _useCases;

  FoodAttendanceBloc(this._useCases) : super(FoodAttendanceState()) {
    on<LoadFoodData>(_onLoadFoodData);
    on<ChangeDate>(_onChangeDate);
    on<AddFood>(_onAddFood);
    on<DeleteFood>(_onDeleteFood);
    on<SearchStudent>(_onSearchStudent);
    on<ClearSearch>(_onClearSearch);
    on<MarkAttendance>(_onMarkAttendance);
    on<LoadStudentsForFood>(_onLoadStudentsForFood);
    on<FoodAttendanceError>(_onFoodAttendanceError);
    on<ScanAndMarkAttendance>(_onScanAndMarkAttendance);
    on<ClearFoodAttendanceMessages>(_onClearFoodAttendanceMessages);
    on<ClearSuccessfullyAttendedStudent>(_onClearSuccessfullyAttendedStudent);
  }

  void _onClearSuccessfullyAttendedStudent(
    ClearSuccessfullyAttendedStudent event,
    Emitter<FoodAttendanceState> emit,
  ) {
    emit(state.copyWith(clearSuccessfullyAttendedStudent: true));
  }

  void _onClearFoodAttendanceMessages(
    ClearFoodAttendanceMessages event,
    Emitter<FoodAttendanceState> emit,
  ) {
    emit(state.copyWith(clearSuccess: true, clearError: true));
  }

  Future<void> _onScanAndMarkAttendance(
    ScanAndMarkAttendance event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    try {
      // Validate QR code format (10-digit number)
      final is10DigitNumber = RegExp(r'^\d{10}$').hasMatch(event.qrCode);
      if (!is10DigitNumber) {
        emit(state.copyWith(errorMessage: 'Invalid QR code.'));
        return;
      }

      final allStudents = await _useCases.getAllStudents();
      final student = allStudents.firstWhere(
        (s) => s.reg == event.qrCode,
        orElse: () => throw Exception('Student not found for QR code.'),
      );

      // Check for duplicate attendance before marking
      final existingStudents = await _useCases.getStudentsForFoodOnDate(
        event.foodId,
        state.selectedDate,
      );
      if (existingStudents.any((s) => s.id == student.id)) {
        emit(
          state.copyWith(
            errorMessage: 'This student\'s attendance has already been marked.',
          ),
        );
      } else {
        final now = DateTime.now();
        final attendanceTime = DateTime(
          state.selectedDate.year,
          state.selectedDate.month,
          state.selectedDate.day,
          now.hour,
          now.minute,
          now.second,
        );
        await _useCases.addStudentFood(
          student.id,
          event.foodId,
          attendanceTime,
        );

        final allRooms = await _useCases.getAllRooms();
        final room = allRooms.firstWhere(
          (r) => r.id == student.roomId,
          orElse: () => RoomEntity(id: -1, name: 'N/A'),
        );

        emit(
          state.copyWith(
            successfullyAttendedStudent: student,
            successfullyAttendedStudentRoom: room,
          ),
        );
        add(LoadFoodData()); // Refresh the main page data
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Error processing QR code: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadFoodData(
    LoadFoodData event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FoodAttendanceStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final foods = await _useCases.getAllFood();
      final records = await _useCases.getStudentsByDate(state.selectedDate);
      final counts = <int, int>{};
      for (final food in foods) {
        final uniqueStudentIds = records
            .where((r) => r.foodId == food.id)
            .map((r) => r.studentId)
            .toSet();
        counts[food.id] = uniqueStudentIds.length;
      }

      final totalUniqueStudents = records
          .map((r) => r.studentId)
          .toSet()
          .length;

      emit(
        state.copyWith(
          status: FoodAttendanceStatus.success,
          foods: foods,
          attendanceCounts: counts,
          totalUniqueStudents: totalUniqueStudents,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FoodAttendanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onChangeDate(
    ChangeDate event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    emit(state.copyWith(selectedDate: event.newDate));
    add(LoadFoodData());
  }

  Future<void> _onAddFood(
    AddFood event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    try {
      await _useCases.addFood(event.foodName);
      emit(state.copyWith(successMessage: 'Food added successfully!'));
      add(LoadFoodData());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        emit(
          state.copyWith(
            errorMessage: 'Food item with this name already exists.',
          ),
        );
      } else {
        emit(
          state.copyWith(errorMessage: 'Failed to add food: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _onDeleteFood(
    DeleteFood event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    try {
      await _useCases.deleteFood(event.foodId);
      emit(state.copyWith(successMessage: 'Food deleted successfully!'));
      add(LoadFoodData());
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to delete food: ${e.toString()}'),
      );
    }
  }

  Future<void> _onSearchStudent(
    SearchStudent event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    emit(state.copyWith(isSearching: true, searchedStudents: []));
    try {
      final allStudents = await _useCases.getAllStudents();
      final students = allStudents
          .where((s) => s.reg.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(state.copyWith(isSearching: false, searchedStudents: students));
    } catch (e) {
      emit(state.copyWith(isSearching: false, errorMessage: e.toString()));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<FoodAttendanceState> emit) {
    emit(state.copyWith(searchedStudents: [], isSearching: false));
  }

  Future<void> _onMarkAttendance(
    MarkAttendance event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    try {
      // 1. Get the list of students who have already had their attendance marked.
      final existingStudents = await _useCases.getStudentsForFoodOnDate(
        event.foodId,
        state.selectedDate,
      );

      // 2. Check if the student is already in the list.
      if (existingStudents.any((student) => student.id == event.studentId)) {
        emit(
          state.copyWith(
            errorMessage: 'This student\'s attendance has already been marked.',
          ),
        );
      } else {
        // 3. If not, add the new attendance record.
        final now = DateTime.now();
        final attendanceTime = DateTime(
          state.selectedDate.year,
          state.selectedDate.month,
          state.selectedDate.day,
          now.hour,
          now.minute,
          now.second,
        );
        await _useCases.addStudentFood(
          event.studentId,
          event.foodId,
          attendanceTime,
        );

        final allStudents = await _useCases.getAllStudents();
        final student = allStudents.firstWhere((s) => s.id == event.studentId);
        final allRooms = await _useCases.getAllRooms();
        final room = allRooms.firstWhere(
          (r) => r.id == student.roomId,
          orElse: () => RoomEntity(id: -1, name: 'N/A'),
        );

        emit(
          state.copyWith(
            successfullyAttendedStudent: student,
            successfullyAttendedStudentRoom: room,
          ),
        );
        add(LoadFoodData()); // Refresh the main page data
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to mark attendance: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadStudentsForFood(
    LoadStudentsForFood event,
    Emitter<FoodAttendanceState> emit,
  ) async {
    emit(state.copyWith(status: FoodAttendanceStatus.loading));
    try {
      final students = await _useCases.getStudentsForFoodOnDate(
        event.foodId,
        event.date,
      );
      emit(
        state.copyWith(
          status: FoodAttendanceStatus.success,
          studentsForFood: students,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FoodAttendanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onFoodAttendanceError(
    FoodAttendanceError event,
    Emitter<FoodAttendanceState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.errorMessage));
  }
}

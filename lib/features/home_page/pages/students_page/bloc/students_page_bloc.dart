// lib/features/home_page/pages/students_page/bloc/students_page_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'students_page_event.dart';
import 'students_page_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentOperationsUseCases studentUseCases;

  StudentBloc(this.studentUseCases) : super(const StudentInitial()) {
    on<LoadStudentsEvent>(_onLoadStudents);
    on<AddStudentEvent>(_onAddStudent);
    on<DeleteSelectedStudentsEvent>(_onDeleteSelectedStudents);
    on<ToggleStudentSelectionEvent>(_onToggleStudentSelection);
    on<ToggleSelectionModeEvent>(_onToggleSelectionMode);
    on<SelectAllStudentsEvent>(_onSelectAllStudents);
    on<ClearSelectionEvent>(_onClearSelection);
    on<FilterByYearGroupEvent>(_onFilterByYearGroup);
    on<ClearFilterEvent>(_onClearFilter);
    on<UpdateStudentRoomEvent>(_onUpdateStudentRoom);
  }

  Future<void> _onUpdateStudentRoom(
    UpdateStudentRoomEvent event,
    Emitter<StudentState> emit,
  ) async {
    if (state is StudentLoaded) {
      try {
        await studentUseCases.updateStudentRoom(event.studentId, event.roomId);
        add(const LoadStudentsEvent());
      } catch (e) {
        emit(StudentError('Failed to update room: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLoadStudents(
    LoadStudentsEvent event,
    Emitter<StudentState> emit,
  ) async {
    try {
      emit(const StudentLoading());

      final students = await studentUseCases.getAllStudents();
      final rooms = await studentUseCases.getAllRooms();

      final Map<String, int> yearGroups = {};
      for (final student in students) {
        String reg = student.reg;
        if (reg.length >= 8) {
          String year = reg.substring(5, 7);
          yearGroups[year] = (yearGroups[year] ?? 0) + 1;
        }
      }

      emit(
        StudentLoaded(students: students, rooms: rooms, yearGroups: yearGroups),
      );
    } catch (e) {
      emit(StudentError('Failed to load students: ${e.toString()}'));
    }
  }

  Future<void> _onAddStudent(
    AddStudentEvent event,
    Emitter<StudentState> emit,
  ) async {
    try {
      await studentUseCases.addStudent(
        event.name,
        event.reg,
        roomId: event.roomId,
      );
      add(const LoadStudentsEvent());
    } catch (e) {
      emit(StudentError('Failed to add student: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteSelectedStudents(
    DeleteSelectedStudentsEvent event,
    Emitter<StudentState> emit,
  ) async {
    if (state is StudentLoaded) {
      try {
        for (final studentId in event.studentIds) {
          await studentUseCases.deleteStudent(studentId);
        }
        add(const LoadStudentsEvent());
      } catch (e) {
        emit(StudentError('Failed to delete students: ${e.toString()}'));
      }
    }
  }

  void _onToggleStudentSelection(
    ToggleStudentSelectionEvent event,
    Emitter<StudentState> emit,
  ) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      final selectedIds = List<int>.from(currentState.selectedStudentIds);

      if (selectedIds.contains(event.studentId)) {
        selectedIds.remove(event.studentId);
      } else {
        selectedIds.add(event.studentId);
      }

      if (selectedIds.isEmpty) {
        emit(
          currentState.copyWith(isSelectionMode: false, selectedStudentIds: []),
        );
      } else {
        emit(currentState.copyWith(selectedStudentIds: selectedIds));
      }
    }
  }

  void _onToggleSelectionMode(
    ToggleSelectionModeEvent event,
    Emitter<StudentState> emit,
  ) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      emit(
        currentState.copyWith(
          isSelectionMode: !currentState.isSelectionMode,
          selectedStudentIds: [],
        ),
      );
    }
  }

  void _onSelectAllStudents(
    SelectAllStudentsEvent event,
    Emitter<StudentState> emit,
  ) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      final allStudentIds = currentState.filteredStudents
          .map((s) => s.id)
          .toList();

      if (currentState.selectedStudentIds.length == allStudentIds.length) {
        emit(currentState.copyWith(selectedStudentIds: []));
      } else {
        emit(currentState.copyWith(selectedStudentIds: allStudentIds));
      }
    }
  }

  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<StudentState> emit,
  ) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      emit(
        currentState.copyWith(selectedStudentIds: [], isSelectionMode: false),
      );
    }
  }

  void _onFilterByYearGroup(
    FilterByYearGroupEvent event,
    Emitter<StudentState> emit,
  ) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      emit(
        currentState.copyWith(
          yearFilter: event.yearGroup,
          selectedStudentIds: [],
          isSelectionMode: false,
        ),
      );
    }
  }

  void _onClearFilter(ClearFilterEvent event, Emitter<StudentState> emit) {
    if (state is StudentLoaded) {
      final currentState = state as StudentLoaded;
      emit(
        currentState.copyWith(
          clearYearFilter: true,
          selectedStudentIds: [],
          isSelectionMode: false,
        ),
      );
    }
  }
}

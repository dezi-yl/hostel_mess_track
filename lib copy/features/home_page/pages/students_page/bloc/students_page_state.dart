// lib/features/home_page/pages/students_page/bloc/students_page_state.dart
import 'package:equatable/equatable.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';

abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {
  const StudentInitial();
}

class StudentLoading extends StudentState {
  const StudentLoading();
}

class StudentLoaded extends StudentState {
  final List<StudentEntity> students;
  final List<RoomEntity> rooms;
  final List<int> selectedStudentIds;
  final bool isSelectionMode;
  final String? yearFilter;
  final Map<String, int> yearGroups;

  const StudentLoaded({
    required this.students,
    required this.rooms,
    this.selectedStudentIds = const [],
    this.isSelectionMode = false,
    this.yearFilter,
    this.yearGroups = const {},
  });

  List<StudentEntity> get filteredStudents {
    if (yearFilter == null) return students;
    return students.where((student) {
      String reg = student.reg;
      if (reg.length >= 8) {
        String year = reg.substring(5, 7); // 5th and 6th index (0-based)
        return year == yearFilter;
      }
      return false;
    }).toList();
  }

  @override
  List<Object?> get props => [
    students,
    rooms,
    selectedStudentIds,
    isSelectionMode,
    yearFilter,
    yearGroups,
  ];

  StudentLoaded copyWith({
    List<StudentEntity>? students,
    List<RoomEntity>? rooms,
    List<int>? selectedStudentIds,
    bool? isSelectionMode,
    String? yearFilter,
    Map<String, int>? yearGroups,
    bool clearYearFilter = false,
  }) {
    return StudentLoaded(
      students: students ?? this.students,
      rooms: rooms ?? this.rooms,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      yearFilter: clearYearFilter ? null : yearFilter ?? this.yearFilter,
      yearGroups: yearGroups ?? this.yearGroups,
    );
  }
}

class StudentError extends StudentState {
  final String message;

  const StudentError(this.message);

  @override
  List<Object> get props => [message];
}
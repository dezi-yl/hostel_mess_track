
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'package:intl/intl.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final StudentOperationsUseCases _studentOperationsUseCases;

  ReportsBloc(this._studentOperationsUseCases) : super(ReportsInitial()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<ExportToCsv>(_onExportToCsv);
  }

  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    try {
      // 1. Fetch all necessary data
      final allRecords = await _studentOperationsUseCases
          .getAllStudentFoodRecords();
      final students = await _studentOperationsUseCases.getAllStudents();
      final foods = await _studentOperationsUseCases.getAllFood();

      // Filter records for the selected month
      final recordsForMonth = allRecords
          .where(
            (record) =>
                record.date.year == event.date.year &&
                record.date.month == event.date.month,
          )
          .toList();

      // 2. Determine unique, sorted list of dates and meal types
      final uniqueDates =
          recordsForMonth
              .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
              .toSet()
              .toList()
            ..sort();
      final uniqueFoods = foods..sort((a, b) => a.name.compareTo(b.name));
      final maxFoodNameLength = uniqueFoods.fold<int>(
          0, (max, food) => food.name.length > max ? food.name.length : max);

      // 3. Create the header row
      final headers = [
        "Student Name",
        "Registration No.",
        ...uniqueDates.map((d) => DateFormat('yyyy-MM-dd').format(d)),
        "Total Days Attended",
      ];

      // 4. Iterate through each student to build rows
      final rows = <List<String>>[];
      final sortedStudents = students..sort((a, b) => a.name.compareTo(b.name));

      for (final student in sortedStudents) {
        final studentRecords = recordsForMonth
            .where((record) => record.studentId == student.id)
            .toList();

        if (studentRecords.isEmpty) continue;

        final row = <String>[student.name, student.reg];
        int totalDaysAttended = 0;

        for (final date in uniqueDates) {
          final mealsOnDateRecords = studentRecords
              .where(
                (r) =>
                    r.date.year == date.year &&
                    r.date.month == date.month &&
                    r.date.day == date.day,
              )
              .toList();

          final mealsOnDate = mealsOnDateRecords.map((r) => r.foodId).toSet();

          if (mealsOnDate.isNotEmpty) {
            totalDaysAttended++;
          }

          final mealStatus = uniqueFoods
              .map((food) {
                final attended = mealsOnDate.contains(food.id);
                final paddedFoodName = food.name.padRight(maxFoodNameLength);
                if (attended) {
                  final record =
                      mealsOnDateRecords.firstWhere((r) => r.foodId == food.id);
                  final time = DateFormat('hh:mm a').format(record.date);
                  return '✅ $paddedFoodName $time';
                } else {
                  return '❌ $paddedFoodName';
                }
              })
              .join('\n');

          row.add(mealStatus);
        }

        row.add(totalDaysAttended.toString());
        rows.add(row);
      }

      emit(
        ReportsLoaded(
          reportData: UnifiedReportData(headers: headers, rows: rows),
        ),
      );
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onExportToCsv(
    ExportToCsv event,
    Emitter<ReportsState> emit,
  ) async {
    if (state is ReportsLoaded) {
      final currentState = state as ReportsLoaded;
      try {
        final List<List<dynamic>> csvData = [
          currentState.reportData.headers,
          ...currentState.reportData.rows,
        ];

        String csv = const ListToCsvConverter().convert(csvData);
        Uint8List bytes = utf8.encode(csv);

        final selectedDate = DateTime.now();
        String fileName =
            "report_${DateFormat('yyyy-MM').format(selectedDate)}.csv";

        // Use FileSaver to save the file
        String? path = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );

        if (path != null && path.isNotEmpty) {
          emit(
            ReportExported(
              message: "Report exported to $path",
              reportData: currentState.reportData,
            ),
          );
        } else {
          emit(const ReportsError("File saving was cancelled."));
        }
      } catch (e) {
        emit(ReportsError(e.toString()));
      }
    }
  }
}

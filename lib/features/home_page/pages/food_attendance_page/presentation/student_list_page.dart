import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/bloc/food_attendance_bloc.dart';
import 'package:intl/intl.dart';

class StudentListPage extends StatefulWidget {
  final int foodId;
  final String foodName;
  final DateTime date;

  const StudentListPage({super.key, required this.foodId, required this.foodName, required this.date});

  @override
  StudentListPageState createState() => StudentListPageState();
}

class StudentListPageState extends State<StudentListPage> {
  @override
  void initState() {
    super.initState();
    context.read<FoodAttendanceBloc>().add(LoadStudentsForFood(foodId: widget.foodId, date: widget.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.foodName),
            Text(DateFormat('EEEE, d MMMM').format(widget.date), style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: BlocBuilder<FoodAttendanceBloc, FoodAttendanceState>(
        builder: (context, state) {
          if (state.status == FoodAttendanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.studentsForFood.isEmpty) {
            return const Center(child: Text('No students have eaten this food today.'));
          }

          final students = state.studentsForFood;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Reg: ${student.reg}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

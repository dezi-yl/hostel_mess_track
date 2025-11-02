import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/utils/snackbar_service.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/bloc/food_attendance_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/presentation/student_list_page.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/presentation/widgets/add_food_dialog.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/presentation/widgets/attendance_dialog.dart';
import 'package:intl/intl.dart';

class FoodAttendancePage extends StatefulWidget {
  const FoodAttendancePage({super.key});

  @override
  State<FoodAttendancePage> createState() => _FoodAttendancePageState();
}

class _FoodAttendancePageState extends State<FoodAttendancePage> {
  @override
  void initState() {
    super.initState();
    context.read<FoodAttendanceBloc>().add(LoadFoodData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Attendance'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddFoodDialog(context)),
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
        ],
      ),
      body: BlocConsumer<FoodAttendanceBloc, FoodAttendanceState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            SnackbarService.showSnackbar(context, state.errorMessage!, isError: true);
          }
          if (state.successMessage != null) {
            SnackbarService.showSnackbar(context, state.successMessage!);
          }
        },
        builder: (context, state) {
          if (state.status == FoodAttendanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('EEEE, d MMMM').format(state.selectedDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Total Eaten: ${state.totalUniqueStudents}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.foods.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No foods added yet.', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.foods.length,
                    itemBuilder: (context, index) {
                      final food = state.foods[index];
                      final count = state.attendanceCounts[food.id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.restaurant, color: Colors.deepOrange),
                          ),
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Attendance: $count'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentListPage(foodId: food.id, foodName: food.name, date: state.selectedDate),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'take_attendance') {
                                _showAttendanceDialog(context, food.id, food.name);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, food.id, food.name);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'take_attendance', child: Text('Take Attendance')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final bloc = context.read<FoodAttendanceBloc>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: bloc.state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != bloc.state.selectedDate) {
      bloc.add(ChangeDate(picked));
    }
  }

  void _showAddFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddFoodDialog(
        onAdd: (name) {
          context.read<FoodAttendanceBloc>().add(AddFood(name));
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int foodId, String foodName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Food'),
        content: Text('Are you sure you want to delete "$foodName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<FoodAttendanceBloc>().add(DeleteFood(foodId));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context, int foodId, String foodName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AttendanceDialog(
        foodId: foodId,
        foodName: foodName,
        onClose: () {
          Navigator.pop(dialogContext);
          context.read<FoodAttendanceBloc>().add(LoadFoodData());
        },
      ),
    );
  }
}

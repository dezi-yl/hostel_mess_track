import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/di/dependency_injection.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'package:hostel_mess_2/features/home_page/nav_bar_screen.dart';

import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/bloc/food_attendance_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/students_page/bloc/students_page_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/debug_page/bloc/debug_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/students_page/bloc/students_page_event.dart';

import 'package:hostel_mess_2/features/home_page/pages/reports_page/bloc/reports_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/room_page/rooms_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // setup GetIt DI
  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              StudentBloc(locator<StudentOperationsUseCases>())
                ..add(const LoadStudentsEvent()), // preload students
        ),
        BlocProvider(
          create: (context) =>
              FoodAttendanceBloc(locator<StudentOperationsUseCases>()),
        ),
        BlocProvider(
          create: (context) => DebugBloc(locator<StudentOperationsUseCases>()),
        ),
        BlocProvider(
          create: (context) =>
              ReportsBloc(locator<StudentOperationsUseCases>()),
        ),
        BlocProvider(
          create: (context) =>
              RoomBloc(locator<StudentOperationsUseCases>())..add(LoadRooms()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hotel Mess',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const NavBarScreen(), // ✅ NavBar with all 4 pages
      ),
    );
  }
}

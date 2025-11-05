import 'package:flutter/material.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';

class SuccessCard extends StatelessWidget {
  final StudentEntity student;
  final RoomEntity? room;

  const SuccessCard({super.key, required this.student, this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reg: ${student.reg}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            if (room != null)
              Text(
                'Room: ${room!.name}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

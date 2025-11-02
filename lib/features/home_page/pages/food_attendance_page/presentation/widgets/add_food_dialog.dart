// lib/features/food_attendance/presentation/widgets/add_food_dialog.dart

import 'package:flutter/material.dart';

class AddFoodDialog extends StatefulWidget {
  final Function(String) onAdd;

  const AddFoodDialog({super.key, required this.onAdd});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Food'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Food Name',
            hintText: 'e.g., Breakfast, Lunch, Dinner',
            prefixIcon: Icon(Icons.restaurant),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a food name';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd(_controller.text.trim());
    }
  }
}

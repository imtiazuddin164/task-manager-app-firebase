import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _dueDate;
  late String _priority;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController = TextEditingController(text: task?.title ?? '');

    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));

    _priority = task?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      // initialDate: _dueDate.isBefore(DateTime.now())
      //     ? DateTime.now()
      //     : _dueDate,
      initialDate: DateUtils.dateOnly(
        _dueDate.isBefore(DateUtils.dateOnly(DateTime.now()))
            ? DateTime.now()
            : _dueDate,
      ),
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;

    if (user == null) return;

    final previous = widget.task;

    final task = TaskModel(
      id: previous?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      isCompleted: previous?.isCompleted ?? false,
      createdAt: previous?.createdAt ?? DateTime.now(),
      userId: user.uid,
    );

    final provider = context.read<TaskProvider>();

    final success = previous == null
        ? await provider.addTask(task)
        : await provider.updateTask(task);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not save task.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Add Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a task title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a description.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    'Due date: '
                    '${_dueDate.toLocal().toString().split(' ').first}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: provider.isLoading ? null : _saveTask,
                  child: provider.isLoading
                      ? const CircularProgressIndicator()
                      : Text(isEditing ? 'Update Task' : 'Save Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

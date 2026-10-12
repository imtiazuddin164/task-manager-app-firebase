//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../providers/auth_provider.dart';
//
// class TaskListScreen extends StatelessWidget {
//   const TaskListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Tasks'),
//         actions: [
//           IconButton(
//             tooltip: 'Sign Out',
//             onPressed: auth.isLoading
//                 ? null
//                 : () async {
//               await context
//                   .read<AuthProvider>()
//                   .signOut();
//             },
//             icon: const Icon(Icons.logout),
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.task_alt,
//                 size: 64,
//                 color: Colors.indigo,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Welcome!',
//                 style: Theme.of(context)
//                     .textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 auth.user?.email ?? 'Signed in successfully',
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Your task management screen will be ready in Step 5.',
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/tasks/task_form_screen.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Future<void> _deleteTask(BuildContext context, TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await context.read<TaskProvider>().deleteTask(
      userId: task.userId,
      taskId: task.id,
    );

    if (!context.mounted) return;

    final message = success
        ? 'Task deleted.'
        : context.read<TaskProvider>().errorMessage ?? 'Could not delete task.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: taskProvider.isLoading
                ? null
                : () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: context.read<TaskProvider>().getTasks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load tasks. Check Firestore rules and connection.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet. Add your first task!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: taskProvider.isLoading
                        ? null
                        : (_) async {
                            final success = await context
                                .read<TaskProvider>()
                                .toggleCompletion(task);

                            if (!context.mounted) return;

                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.read<TaskProvider>().errorMessage ??
                                        'Could not update task.',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '${task.priority} priority • '
                    'Due: ${task.dueDate.toLocal().toString().split(' ').first}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete task',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: taskProvider.isLoading
                        ? null
                        : () => _deleteTask(context, task),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(task: task),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

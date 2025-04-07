import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('task-${task.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل تريد حذف المهمة "${task.title}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 2,
        child: InkWell(
          onTap: () {
            onStatusChanged(!task.completed);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.completed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Checkbox(
                    value: task.completed,
                    onChanged: (value) {
                      onStatusChanged(value ?? false);
                    },
                    shape: const CircleBorder(),
                    activeColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.completed ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          /* Text(
                            _getFormattedDate(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),*/
                          const SizedBox(width: 8),
                          Icon(
                            task.completed
                                ? Icons.check_circle
                                : Icons.pending_actions,
                            size: 12,
                            color:
                                task.completed ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.completed ? 'مكتملة' : 'قيد التنفيذ',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  task.completed ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.swipe_left,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*String _getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      task.createdAt.year,
      task.createdAt.month,
      task.createdAt.day,
    );

    if (taskDate == today) {
      return 'اليوم';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}';
    }
  }*/
}

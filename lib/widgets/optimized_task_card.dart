import 'package:flutter/material.dart';
import '../delivery_task_model.dart';

class OptimizedTaskCard extends StatelessWidget {
  final DeliveryTask task;
  final VoidCallback? onTap;

  const OptimizedTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.isCompleted).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.isCompleted ? 'Selesai' : 'Pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(task.isCompleted),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Task ID
              Text(
                'ID: ${task.id}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Task Title
              Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Description (if available)
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Status icon
              Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.check_circle : Icons.pending_actions,
                    size: 16,
                    color: _getStatusColor(task.isCompleted),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.isCompleted ? 'Sudah selesai' : 'Sedang proses',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(task.isCompleted),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isCompleted) {
    return isCompleted ? Colors.green : Colors.orange;
  }
}
import 'package:flutter/material.dart';
import '../../models/routine.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onClearRunData;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExport,
    this.onClearRunData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased padding for mobile
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: theme.textTheme.headlineSmall?.copyWith( // Larger text for mobile
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (routine.category.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      routine.category,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Larger touch target for menu button
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'export':
                            onExport?.call();
                            break;
                          case 'clearRunData':
                            onClearRunData?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clearRunData',
                          child: Row(
                            children: [
                              Icon(Icons.history_toggle_off, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Clear Run Data', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (routine.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  routine.description,
                  style: theme.textTheme.bodyLarge?.copyWith( // Larger body text
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: 20, // Larger icon
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${routine.stepCount} step${routine.stepCount != 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(100, 44), // Larger touch target
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // Last run information
              const SizedBox(height: 12),
              FutureBuilder<DateTime?>(
                future: routine.lastRunAt,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  
                  final lastRun = snapshot.data;
                  if (lastRun == null) {
                    return Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Never run',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }
                  
                  final now = DateTime.now();
                  final difference = now.difference(lastRun);
                  String timeAgo;
                  
                  if (difference.inDays > 0) {
                    timeAgo = '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
                  } else if (difference.inHours > 0) {
                    timeAgo = '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
                  } else if (difference.inMinutes > 0) {
                    timeAgo = '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
                  } else {
                    timeAgo = 'Just now';
                  }
                  
                  return Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last run: $timeAgo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
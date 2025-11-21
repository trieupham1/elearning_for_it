import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_summary.dart';

class DeadlineTimeline extends StatelessWidget {
  final List<UpcomingDeadline> deadlines;

  const DeadlineTimeline({super.key, required this.deadlines});

  @override
  Widget build(BuildContext context) {
    if (deadlines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No upcoming deadlines',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deadlines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deadline = deadlines[index];
        return _DeadlineCard(deadline: deadline);
      },
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final UpcomingDeadline deadline;

  const _DeadlineCard({
    required this.deadline,
  });

  Color _getUrgencyColor() {
    if (deadline.isOverdue) return Colors.red;
    if (deadline.isUrgent) return Colors.orange;
    if (deadline.daysUntilDue <= 3) return Colors.amber;
    return Colors.green;
  }

  IconData _getTypeIcon() {
    return deadline.type == 'quiz' ? Icons.quiz : Icons.assignment;
  }

  String _getTimeUntilText() {
    if (deadline.isOverdue) {
      return 'Overdue';
    } else if (deadline.hoursUntilDue < 24) {
      return '${deadline.hoursUntilDue}h left';
    } else {
      return '${deadline.daysUntilDue}d left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    final typeText = deadline.type == 'quiz' ? 'Quiz' : 'Assignment';

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getTypeIcon(), color: urgencyColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadline.title.isNotEmpty ? deadline.title : 'Untitled $typeText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deadline.courseTitle.isNotEmpty ? deadline.courseTitle : 'Unknown Course',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(deadline.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: urgencyColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getTimeUntilText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_item.dart';
import '../models/course.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // Use Course.fromMap to match your database structure
  final List<Course> _courses = [
    Course.fromMap({
      'id': 'cpm502071',
      'code': 'CPM502071',
      'name': 'Cross-Platform Mobile Development',
      'description': 'Learn to build mobile apps with Flutter',
      'color': '#2196F3',
      'image': 'https://picsum.photos/400/200?random=1',
      'students': 48,
    }),
    Course.fromMap({
      'id': 'dbs401',
      'code': 'DBS401',
      'name': 'Database Management Systems',
      'description': 'Relational databases and SQL',
      'color': '#4CAF50',
      'image': 'https://picsum.photos/400/200?random=2',
      'students': 62,
    }),
    Course.fromMap({
      'id': 'ai501',
      'code': 'AI501',
      'name': 'Artificial Intelligence',
      'description': 'Intro to machine learning',
      'color': '#9C27B0',
      'image': 'https://picsum.photos/400/200?random=3',
      'students': 39,
    }),
  ];

  final List<Map<String, String>> _activities = [
    {
      'title': 'Assignment submitted',
      'subtitle': 'You submitted Assignment 2 for CPM502071',
      'time': '10 minutes ago',
    },
    {
      'title': 'New material posted',
      'subtitle': 'Week 6 slides posted in DBS401',
      'time': '2 hours ago',
    },
    {
      'title': 'Quiz reminder',
      'subtitle': 'Quiz on Chapter 4 tomorrow',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Refreshed')));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    StatCard(
                      title: 'Courses',
                      value: '3',
                      icon: Icons.book,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Completed',
                      value: '12',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Pending',
                      value: '4',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Notifications',
                      value: '2',
                      icon: Icons.notifications,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // My Courses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Courses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Show all courses')),
                    );
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _courses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final c = _courses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/course-detail',
                        arguments: c,
                      );
                    },
                    child: SizedBox(
                      width: 260,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            Container(
                              width: 100,
                              height: 140,
                              decoration: BoxDecoration(
                                color: c.color,
                                image: c.image.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(c.image),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          c.color.withOpacity(0.6),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                              ),
                              child: c.image.isEmpty
                                  ? Center(
                                      child: Text(
                                        c.title.isNotEmpty ? c.title[0] : '?',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.code,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'Progress',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    const LinearProgressIndicator(
                                      value: 0.6,
                                      minHeight: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(
                  Icons.add_box,
                  'Join Class',
                  () => _showJoinClassDialog(context),
                ),
                _actionButton(
                  Icons.checklist,
                  'My Assignments',
                  () => _showPlaceholder(context, 'Assignments'),
                ),
                _actionButton(
                  Icons.schedule,
                  'Calendar',
                  () => _showPlaceholder(context, 'Calendar'),
                ),
                _actionButton(
                  Icons.forum,
                  'Discussions',
                  () => _showPlaceholder(context, 'Discussions'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Activities
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _activities.map((a) {
                  return Column(
                    children: [
                      ActivityItem(
                        title: a['title']!,
                        subtitle: a['subtitle']!,
                        time: a['time']!,
                      ),
                      if (a != _activities.last) const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  ElevatedButton _actionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Class'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Class Code',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title not implemented yet')));
  }
}

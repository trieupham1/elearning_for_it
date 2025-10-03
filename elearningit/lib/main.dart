import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Theme configuration
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF1976D2),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

void main() {
  runApp(const ELearningApp());
}

class ELearningApp extends StatelessWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning Management System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/instructor-home': (context) => const InstructorDashboard(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() {
    setState(() => _isLoading = true);
    
    // Simulate login
    Future.delayed(const Duration(seconds: 1), () {
      if (_usernameController.text == 'admin' && _passwordController.text == 'admin') {
        Navigator.pushReplacementNamed(context, '/instructor-home');
      } else {
        Navigator.pushReplacementNamed(context, '/student-home');
      }
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Container(
            width: isWeb && screenWidth > 600 ? 400 : double.infinity,
            margin: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'E-Learning System',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faculty of Information Technology',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Student Home Screen
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _selectedSemester = 'Semester 1 - 2025-2026';
  final List<String> _semesters = [
    'Semester 1 - 2025-2026',
    'Semester 2 - 2024-2025',
    'Semester 1 - 2024-2025',
  ];

  final List<Map<String, dynamic>> _courses = [
    {
      'name': 'Cross-Platform Mobile Development',
      'code': 'CPM502071',
      'instructor': 'Mai Van Manh',
      'color': Colors.blue,
      'image': 'https://picsum.photos/400/200?random=1',
    },
    {
      'name': 'Database Management Systems',
      'code': 'DBS401',
      'instructor': 'Nguyen Van A',
      'color': Colors.green,
      'image': 'https://picsum.photos/400/200?random=2',
    },
    {
      'name': 'Artificial Intelligence',
      'code': 'AI501',
      'instructor': 'Tran Thi B',
      'color': Colors.purple,
      'image': 'https://picsum.photos/400/200?random=3',
    },
    {
      'name': 'Web Programming & Applications',
      'code': 'WEB301',
      'instructor': 'Le Van C',
      'color': Colors.orange,
      'image': 'https://picsum.photos/400/200?random=4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          // Semester Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSemester,
                icon: const Icon(Icons.arrow_drop_down),
                items: _semesters.map((String semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSemester = newValue!;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
            }
            
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3/2,
              ),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return _buildCourseCard(course, context);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJoinClassDialog(context),
        tooltip: 'Join Class',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: course['color'],
                image: DecorationImage(
                  image: NetworkImage(course['image']),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    course['color'].withOpacity(0.8),
                    BlendMode.darken,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    course['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    course['code'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course['instructor'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.assignment, size: 20),
                          onPressed: () {},
                          tooltip: 'Assignments',
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder, size: 20),
                          onPressed: () {},
                          tooltip: 'Materials',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Nguyen Van Student'),
            accountEmail: const Text('student@fit.edu.vn'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'NS',
                style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentDashboard()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendar'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('To-Do'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
            hintText: 'Enter class code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationItem(
                    'New Assignment',
                    'Assignment 3 has been posted in Mobile Development',
                    '2 hours ago',
                    Icons.assignment,
                    false,
                  ),
                  _buildNotificationItem(
                    'Quiz Reminder',
                    'Quiz on Chapter 4 starts tomorrow',
                    '5 hours ago',
                    Icons.quiz,
                    false,
                  ),
                  _buildNotificationItem(
                    'New Material',
                    'Lecture slides for Week 8 available',
                    'Yesterday',
                    Icons.folder,
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String time, IconData icon, bool isRead) {
    return Container(
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey.shade300 : Theme.of(context).primaryColor,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(time, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// Course Detail Screen with Tabs
class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course['name']),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stream', icon: Icon(Icons.forum)),
            Tab(text: 'Classwork', icon: Icon(Icons.assignment)),
            Tab(text: 'People', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamTab(),
          _buildClassworkTab(),
          _buildPeopleTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: () => _showNewPostDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStreamTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnnouncementCard(
          'Welcome to the course!',
          'Welcome everyone to Cross-Platform Mobile Development. Please check the syllabus in the Classwork tab.',
          'Mai Van Manh',
          '2 days ago',
          3,
        ),
        _buildAnnouncementCard(
          'Assignment 1 Posted',
          'The first assignment has been posted. Due date is next Friday.',
          'Mai Van Manh',
          '1 week ago',
          5,
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(String title, String content, String author, String time, int comments) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.course['color'],
                  child: Text(author[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment, size: 18),
                  label: Text('$comments comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassworkTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search assignments, quizzes, materials...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Filter Chips
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Assignments'),
              selected: true,
              onSelected: (bool value) {},
            ),
            FilterChip(
              label: const Text('Quizzes'),
              selected: false,
              onSelected: (bool value) {},
            ),
            FilterChip(
              label: const Text('Materials'),
              selected: false,
              onSelected: (bool value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildClassworkItem(Icons.assignment, 'Assignment 1', 'Build a Flutter App', 'Due Friday, 11:59 PM', Colors.blue),
        _buildClassworkItem(Icons.quiz, 'Quiz 1', 'Chapter 1-3', 'Due Monday, 3:00 PM', Colors.orange),
        _buildClassworkItem(Icons.folder, 'Week 1 Materials', 'Lecture slides and resources', 'Posted 2 weeks ago', Colors.green),
        _buildClassworkItem(Icons.assignment, 'Assignment 2', 'State Management', 'Due Next Friday', Colors.blue),
      ],
    );
  }

  Widget _buildClassworkItem(IconData icon, String title, String subtitle, String info, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(info, style: const TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildPeopleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Instructor Section
        const Text('Instructor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Text('MM'),
            ),
            title: const Text('Mai Van Manh'),
            subtitle: const Text('Course Instructor'),
            trailing: IconButton(
              icon: const Icon(Icons.email),
              onPressed: () {},
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Groups Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Chip(label: const Text('3 groups')),
          ],
        ),
        const SizedBox(height: 8),
        _buildGroupCard('Group 1', 15),
        _buildGroupCard('Group 2', 18),
        _buildGroupCard('Group 3', 12),
      ],
    );
  }

  Widget _buildGroupCard(String groupName, int studentCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(groupName),
        subtitle: Text('$studentCount students'),
        children: [
          for (int i = 1; i <= 3; i++)
            ListTile(
              leading: CircleAvatar(
                child: Text('S$i'),
              ),
              title: Text('Student $i'),
              subtitle: Text('student$i@fit.edu.vn'),
              dense: true,
            ),
          if (studentCount > 3)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('... and ${studentCount - 3} more students'),
            ),
        ],
      ),
    );
  }

  void _showNewPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share with your class'),
        content: TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share something with your class...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

// Instructor Dashboard
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String _selectedSemester = 'Semester 1 - 2025-2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildInstructorDrawer(context),
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          // Semester Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSemester,
                items: ['Semester 1 - 2025-2026', 'Semester 2 - 2024-2025']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSemester = newValue!;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : 
                                       constraints.maxWidth > 600 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Courses', '4', Icons.book, Colors.blue),
                    _buildStatCard('Groups', '12', Icons.group, Colors.green),
                    _buildStatCard('Students', '156', Icons.people, Colors.orange),
                    _buildStatCard('Assignments', '24', Icons.assignment, Colors.purple),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton('Create Course', Icons.add_box, () => _showCreateCourseDialog(context)),
                _buildActionButton('Add Students', Icons.person_add, () => _showAddStudentsDialog(context)),
                _buildActionButton('Import CSV', Icons.upload_file, () {}),
                _buildActionButton('Export Reports', Icons.download, () {}),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Activities
            const Text('Recent Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildActivityItem('New assignment submitted', 'Nguyen Van A submitted Assignment 3', '10 minutes ago'),
                  const Divider(),
                  _buildActivityItem('Quiz completed', '15 students completed Quiz 2', '1 hour ago'),
                  const Divider(),
                  _buildActivityItem('Material viewed', '45 students viewed Week 8 materials', '3 hours ago'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCourseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(time, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildInstructorDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Admin'),
            accountEmail: const Text('admin@fit.edu.vn'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'AD',
                style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Courses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CourseManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Students'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Question Bank'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  void _showCreateCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Number of Sessions',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['10', '15'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {},
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStudentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Students', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Manual Entry'),
                        Tab(text: 'CSV Import'),
                      ],
                    ),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          // Manual Entry Tab
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Student Name',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Student ID',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // CSV Import Tab
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text('Drag and drop CSV file here'),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Browse Files'),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'CSV Format: Name, Email, Student ID',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Student Dashboard
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Learning Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildProgressItem('Assignments Submitted', 8, 12, Colors.blue),
                    const SizedBox(height: 12),
                    _buildProgressItem('Quizzes Completed', 5, 8, Colors.green),
                    const SizedBox(height: 12),
                    _buildProgressItem('Materials Viewed', 15, 20, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Upcoming Deadlines
            const Text('Upcoming Deadlines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildDeadlineItem('Mobile Dev Assignment 3', 'Tomorrow, 11:59 PM', Colors.red),
                  const Divider(height: 1),
                  _buildDeadlineItem('Database Quiz 4', 'Friday, 3:00 PM', Colors.orange),
                  const Divider(height: 1),
                  _buildDeadlineItem('AI Project Proposal', 'Next Monday', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Recent Grades
            const Text('Recent Grades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildGradeItem('Assignment 2', '85/100', 'Mobile Development'),
                  const Divider(height: 1),
                  _buildGradeItem('Quiz 3', '18/20', 'Database Systems'),
                  const Divider(height: 1),
                  _buildGradeItem('Lab Exercise 5', '95/100', 'Web Programming'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int completed, int total, Color color) {
    final progress = completed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$completed/$total'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem(String title, String deadline, Color urgencyColor) {
    return ListTile(
      leading: Icon(Icons.schedule, color: urgencyColor),
      title: Text(title),
      subtitle: Text(deadline),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildGradeItem(String assignment, String grade, String course) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: Icon(Icons.grade, color: Colors.green),
      ),
      title: Text(assignment),
      subtitle: Text(course),
      trailing: Text(grade, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// Course Management Screen
class CourseManagementScreen extends StatelessWidget {
  const CourseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCourseManagementCard(
            'Cross-Platform Mobile Development',
            'CPM502071',
            '4 groups • 52 students',
            Colors.blue,
          ),
          _buildCourseManagementCard(
            'Database Management Systems',
            'DBS401',
            '3 groups • 45 students',
            Colors.green,
          ),
          _buildCourseManagementCard(
            'Artificial Intelligence',
            'AI501',
            '2 groups • 30 students',
            Colors.purple,
          ),
          _buildCourseManagementCard(
            'Web Programming & Applications',
            'WEB301',
            '3 groups • 29 students',
            Colors.orange,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseManagementCard(String name, String code, String info, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(code.substring(0, 2), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(code),
            const SizedBox(height: 4),
            Text(info, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Edit')),
            const PopupMenuItem(child: Text('Manage Groups')),
            const PopupMenuItem(child: Text('View Students')),
            const PopupMenuItem(child: Text('Export Data')),
            const PopupMenuItem(child: Text('Delete')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Student Management Screen
class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: 'All Courses',
                  items: ['All Courses', 'Mobile Dev', 'Database', 'AI', 'Web'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {},
                ),
              ],
            ),
          ),
          // Student List
          Expanded(
            child: ListView(
              children: [
                _buildStudentItem('Nguyen Van An', 'ST001', 'Mobile Dev - Group 1'),
                _buildStudentItem('Tran Thi Binh', 'ST002', 'Mobile Dev - Group 1'),
                _buildStudentItem('Le Van Cuong', 'ST003', 'Mobile Dev - Group 2'),
                _buildStudentItem('Pham Thi Dung', 'ST004', 'Database - Group 1'),
                _buildStudentItem('Hoang Van Em', 'ST005', 'AI - Group 1'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildStudentItem(String name, String id, String course) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name.substring(0, 2).toUpperCase()),
        ),
        title: Text(name),
        subtitle: Text('$id • $course'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('View Profile')),
            const PopupMenuItem(child: Text('Edit')),
            const PopupMenuItem(child: Text('Change Group')),
            const PopupMenuItem(child: Text('View Progress')),
            const PopupMenuItem(child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: kIsWeb ? 600 : double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Text('NS', style: TextStyle(fontSize: 36, color: Colors.white)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nguyen Van Student',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('student@fit.edu.vn'),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildProfileField('Full Name', 'Nguyen Van Student', false),
                        _buildProfileField('Student ID', 'ST2021001', false),
                        _buildProfileField('Email', 'student@fit.edu.vn', false),
                        _buildProfileField('Phone', '+84 123 456 789', true),
                        _buildProfileField('Address', '123 Nguyen Hue, District 1, HCMC', true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Academic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildProfileField('Department', 'Information Technology', false),
                        _buildProfileField('Year', '3rd Year', false),
                        _buildProfileField('GPA', '3.65/4.0', false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (isEditable)
            Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'ai_tutor.dart';
import 'focus_mode_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String? _selectedPreference;
  late AnimationController _controller;
  late Animation<double> _animation;

  List<String> subjectNames = [
    'Maths', 'Science', 'History', 'Language', 'Arts',
    'Geography', 'Music', 'Computer', 'Physics', 'Biology',
  ];

  List<String> videoTitles = [
    'C++ Basics in One Shot - Strivers A2Z DSA Course - L1',
    'Introduction to JavaScript + Setup | JavaScript Tutorial in Hindi #1', 
    'Python Tutorial for Beginners | Learn Python in 1.5 Hours',
    'ApnaCollegeOfficial which Coding Platform should I study from?',
    'Web Development Tutorial for Beginners (2024 Edition)',
  ];

  List<String> videoImageUrls = [
    'https://th.bing.com/th/id/OIP.0STrpvtmnpiN8MxYI-xUPwAAAA?rs=1&pid=ImgDetMain',
    'https://www.codewithharry.com/_next/image/?url=https:%2F%2Fcwh-full-next-space.fra1.digitaloceanspaces.com%2Fvideoseries%2Fultimate-js-tutorial-hindi-1%2FJS-Thumb.jpg&w=828&q=75',
    'https://th.bing.com/th/id/OIP.raiOFsxSpMFzOFwa2TXUmQAAAA?rs=1&pid=ImgDetMain',
    'https://i.ytimg.com/vi/qTph1pj_rCo/maxresdefault.jpg',
    'https://www.someurl.com/your-image4.jpg',
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AiTutorPage()),
        );
        break;
    }
  }

  void _navigateToFocusMode() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => FocusModePage()),
    );
  }

  final TextEditingController _taskController = TextEditingController();
  List<String> tasks = [];

  void _addTask(String task) {
    setState(() {
      tasks.add(task);
      _taskController.clear();
      _controller.forward(from: 0.0);
    });
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('EduAI', 
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    // backgroundImage: AssetImage('lib/assets/profile_icon.jpg'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vidyasaagar',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black54),
              title: Text('Settings',
                style: GoogleFonts.montserrat(fontSize: 16)
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.black54),
              title: Text('FAQ',
                style: GoogleFonts.montserrat(fontSize: 16)
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search courses',
                          hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          suffixIcon: const Icon(Icons.search, color: Colors.black54),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      alignment: Alignment.center,
                      child: DropdownButton<String>(
                        hint: Text(
                          'Preference',
                          style: GoogleFonts.montserrat(color: Colors.black54),
                        ),
                        value: _selectedPreference,
                        items: ['Visual', 'Auditory', 'Reading/Writing', 'Kinesthetic']
                            .map((String preference) {
                          return DropdownMenuItem<String>(
                            value: preference,
                            child: Text(
                              preference,
                              style: GoogleFonts.montserrat(),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPreference = newValue;
                          });
                        },
                        icon: const Icon(Icons.tune, color: Colors.black54),
                        underline: Container(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Recommended for you',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: videoTitles.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              videoImageUrls[index],
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black87,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  videoTitles[index],
                                  maxLines: 2,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Subjects',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subjectNames.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildSubjectCard(subjectNames[index], index);
                  },
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Your Tasks',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: 'Add a new task',
                    hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.black54, size: 28),
                      onPressed: () => _addTask(_taskController.text.trim()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: ListTile(
                          title: Text(
                            tasks[index],
                            style: GoogleFonts.montserrat(fontSize: 16),
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteTask(index),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.montserrat(),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded),
              label: 'My Learning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_rounded),
              label: 'AI Tutor',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToFocusMode,
        backgroundColor: Colors.black87,
        elevation: 2,
        child: const Icon(Icons.timer_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSubjectCard(String subjectName, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.book_rounded,
            size: 45,
            color: Colors.black87,
          ),
          const SizedBox(height: 10),
          Text(
            subjectName,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

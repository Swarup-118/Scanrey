import 'package:flutter/material.dart';
import 'gallery_screen.dart';
import 'face_search_screen.dart';

const kBg      = Color(0xFF080C14);
const kSurface = Color(0xFF0F1623);
const kAccent  = Color(0xFF4F8EF7);
const kGold    = Color(0xFFFFD166);
const kWhite   = Color(0xFFF5F5F5);
const kDim     = Color(0xFF5A6A7A);
const kBorder  = Color(0xFF1A2535);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    GalleryScreen(),
    _PlaceholderScreen(icon: Icons.search_rounded,      label: 'Search'),
    FaceSearchScreen(),
    _PlaceholderScreen(icon: Icons.auto_delete_rounded, label: 'Junk'),
    _PlaceholderScreen(icon: Icons.settings_rounded,    label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurface,
          border: const Border(
            top: BorderSide(color: kBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: kAccent,
          unselectedItemColor: kDim,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library_rounded),
              label: 'Gallery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.face_outlined),
              activeIcon: Icon(Icons.face_rounded),
              label: 'Faces',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_delete_outlined),
              activeIcon: Icon(Icons.auto_delete_rounded),
              label: 'Junk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderScreen({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: kBorder),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDim,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 13, color: kBorder),
            ),
          ],
        ),
      ),
    );
  }
}
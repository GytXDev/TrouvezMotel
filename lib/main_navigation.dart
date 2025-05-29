import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    Container(), // sera ignoré (on utilise le bottom sheet pour "Ajouter")
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialIndex = ModalRoute.of(context)?.settings.arguments as int?;
    _currentIndex = initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      // ✅ BottomSheet élégant
    } else {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Accueil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: "Ajouter"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Compte"),
        ],
      ),
    );
  }
}

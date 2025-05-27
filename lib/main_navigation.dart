import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/motels/add_motel_screen.dart';
import 'screens/restaurants/add_restaurant_screen.dart';
import 'screens/appartements/add_appartement_screen.dart';
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
      final selected = await showModalBottomSheet<String>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Quel type souhaitez-vous ajouter ?",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAddOption(
                    icon: Icons.hotel,
                    label: "Motel",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddMotelScreen()),
                      );
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.restaurant,
                    label: "Restaurant",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/addRestaurant');
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.apartment,
                    label: "Appartement",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/addAppartement');
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      );
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

Widget _buildAddOption({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(16),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
        SizedBox(height: 8),
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

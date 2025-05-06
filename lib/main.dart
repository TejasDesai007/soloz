import 'package:flutter/material.dart';
import 'package:soloz/screens/home_screen.dart';
import 'package:soloz/screens/products.dart';
import 'package:soloz/utils/theme.dart';
import 'package:soloz/services/firebase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soloz/screens/profilescreen.dart';
import 'package:soloz/screens/cart.dart';
import 'package:soloz/screens/splash_screen.dart'; // Import the splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soloz - Clothing Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Use SplashScreen and pass MainScreen as the next screen to show
      home: SplashScreen(nextScreen: const MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onExplore: () {
          setState(() {
            _currentIndex = 1; // Switch to Products tab
          });
        },
      ),
      const ProductScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.black, Colors.black],
              center: Alignment(-1, 0),
              radius: 5,
            ),
          ),
          child: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FontAwesomeIcons.shopify, size: 30.0, color: Colors.amber),
                const SizedBox(width: 10),
                const Text(
                  ' SoloZ ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.shirt),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.shoppingCart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

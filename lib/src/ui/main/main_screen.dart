import 'package:flutter/material.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/ui/main/home/home_screen.dart';
import 'package:sahhof/src/ui/main/mybook/my_book_screen.dart';
import 'package:sahhof/src/ui/main/profile/profile_screen.dart';
import 'package:sahhof/src/ui/main/search/serach_screen.dart';
import 'package:sahhof/src/ui/mini_audio_player.dart';
import 'package:sahhof/src/utils/cache.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  List<Widget> pages = [
    HomeScreen(),
    SearchScreen(),
    MyBooksPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomSheet: MiniAudioPlayer(),
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
          currentIndex: selectedIndex,
          onTap: (index){
            setState(() {
              selectedIndex = index;
            });},
          items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled),label: "Asosiy"),
        BottomNavigationBarItem(icon: Icon(Icons.search),label: "Qidiruv"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt),label: "Kutubxona"),
      ]),
    );
  }
}

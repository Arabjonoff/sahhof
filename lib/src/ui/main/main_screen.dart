import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_handler.dart';
import 'package:sahhof/src/ui/main/home/home_screen.dart';
import 'package:sahhof/src/ui/main/search/serach_screen.dart';
import 'package:sahhof/src/ui/main/mybook/my_audio_screen.dart';
import 'package:sahhof/src/ui/mini_audio_player.dart';

import '../../bloc/pdf/pdf_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import 'detail/audio/audio_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AudioPlayerHandler? get handler => AudioScreen.globalHandler;

  @override
  void initState() {
    super.initState();
    profileBloc.getAllProfile();
  }

  int selectedIndex = 0;

  List<Widget> get pages => [
    HomeScreen(),
    SearchScreen(),
    MyDownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: selectedIndex,
                      children: pages,
                    ),
                  ),

                  /// Mini player uchun joy bo‘shatish
                  StreamBuilder<MediaItem?>(
                    stream: handler?.mediaItem,
                    builder: (context, snapshot) {
                      if (handler == null || snapshot.data == null) {
                        return SizedBox(height: 0);
                      }

                      final mediaItem = snapshot.data;

                      return MiniPlayer(
                        audioPlayer: handler!.player,
                        mediaItem: mediaItem,
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) => AudioScreen(data: handler!.cu!),
                          //   ),
                          // );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          pdfBloc.getPdfFiles();
          setState(() => selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Asosiy",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Qidiruv",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Kutubxona",
          ),
        ],
      ),
    );
  }
}



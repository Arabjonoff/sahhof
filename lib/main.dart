import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sahhof/src/ui/main/detail/audio/backround_download.dart';
import 'package:sahhof/src/ui/main/main_screen.dart';
import 'package:sahhof/src/ui/splash/splash_screen.dart';
import 'package:sahhof/src/utils/cache.dart';

void main() async {
  // WidgetsFlutterBinding - faqat bir marta
  WidgetsFlutterBinding.ensureInitialized();

  // Background download service initialize (optional)
  try {
    await BackgroundDownloadService().initialize();
  } catch (e) {
    print('Background download service init error: $e');
    // Continue even if this fails
  }

  // Cache service initialize
  await CacheService.init();

  // Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sahhof',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
          ),
          home: child,
        );
      },
      child: CacheService.getToken() == ''
          ? const SplashScreen()
          : const MainScreen(),
    );
  }
}
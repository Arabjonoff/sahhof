import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_handler.dart';
import 'package:sahhof/src/ui/main/detail/audio/backround_download.dart';
import 'package:sahhof/src/ui/main/main_screen.dart';
import 'package:sahhof/src/ui/splash/splash_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );
  try {
    await BackgroundDownloadService().initialize();
  } catch (e) {
    print('Background download service init error: $e');
  }
  await CacheService.init();

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
      child:MainScreen(),
    );
  }
}
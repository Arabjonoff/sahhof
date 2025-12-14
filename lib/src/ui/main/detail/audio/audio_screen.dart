import 'package:audio_service/audio_service.dart'as audio_service_pkg;
import 'package:cached_network_image/cached_network_image.dart' hide DownloadProgress;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_position_screen.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';
import 'package:sahhof/src/ui/main/detail/audio/simple_download.dart';
import 'dart:async';

import '../../../../model/book/book_detail.dart';
import '../../../../utils/permission_helper.dart';
import 'audio_handler.dart' show AudioPlayerHandler;
import '../../../../theme/app_colors.dart';

class AudioScreen extends StatefulWidget {
  final BookDetailModel data;
  const AudioScreen({super.key, required this.data});
  static AudioPlayerHandler? _globalAudioHandler;

  static AudioPlayerHandler? get globalHandler => _globalAudioHandler;
  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> with WidgetsBindingObserver {

  AudioPlayer? _audioPlayer;
  AudioPlayerHandler? _audioHandler;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isDragging = false;
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.off;

  // Download related
  final AudioDownloadManager _downloadManager = AudioDownloadManager();
  final SimpleBackgroundDownloader _backgroundDownloader = SimpleBackgroundDownloader();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  StreamSubscription<DownloadProgress>? _downloadProgressSubscription;

  // StreamSubscriptions
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _currentIndexSubscription;

  // Position save timer
  Timer? _positionSaveTimer;

  // Global AudioService instance
  static AudioPlayerHandler? _globalAudioHandler;
  static AudioPlayerHandler? get globalHandler => _globalAudioHandler;
  static bool _isAudioServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioService();
    _checkDownloadStatus();
    _listenToDownloadProgress();
    _startAutoSaveTimer();
    _audioHandler = AudioPlayerHandler();
    AudioScreen._globalAudioHandler = _audioHandler;
  }

  // Pozitsiyani har 5 sekundda avtomatik saqlash
  void _startAutoSaveTimer() {
    _positionSaveTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_isPlaying && _position.inSeconds > 0) {
        _saveCurrentPosition();
      }
    });
  }

  // Pozitsiyani saqlash
  Future<void> _saveCurrentPosition() async {
    try {
      await AudioPositionService.savePosition(
        widget.data.id,
        _position,
        _currentIndex,
      );
    } catch (e) {
      debugPrint('Pozitsiya saqlashda xatolik: $e');
    }
  }

  Future<void> _initAudioService() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // ✅ AudioService allaqachon ishga tushganligini tekshirish
      if (_isAudioServiceInitialized && _globalAudioHandler != null) {
        debugPrint('✅ AudioService allaqachon ishga tushgan, mavjudini ishlatamiz');
        _audioHandler = _globalAudioHandler;
        _audioPlayer = _audioHandler!.player;
        _isInitialized = true;

        // ✅ Stream subscriptions ni sozlash
        _setupStreamSubscriptions();

        // Audio player ni initialization qilish
         _initAudioPlayer();
        return;
      }

      // ❌ Agar ishga tushmagan bo'lsa, yangi AudioService yaratish
      debugPrint('🔵 AudioService ni yangi yaratish...');
      _audioHandler = await audio_service_pkg.AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const audio_service_pkg.AudioServiceConfig(
          androidNotificationChannelId: 'uz.naqshsoft.sahhof',
          androidNotificationChannelName: 'Sahhof Audio Playback',
          androidNotificationChannelDescription: 'Audio kitoblarni tinglash',
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );

      // Global instance ni saqlash
      _globalAudioHandler = _audioHandler;
      _isAudioServiceInitialized = true;

      _audioPlayer = _audioHandler!.player;
      _isInitialized = true;

      // ✅ Stream subscriptions ni sozlash
      _setupStreamSubscriptions();

      // Audio player ni initialization qilish
       _initAudioPlayer();

    } catch (e) {
      debugPrint('Audio service init error: $e');

      // Agar xato "already initialized" bo'lsa, global instance ni ishlatamiz
      if (e.toString().contains('cacheManager') ||
          e.toString().contains('already') ||
          e.toString().contains('initialized')) {
        debugPrint('⚠️ AudioService allaqachon initialized, mavjudini ishlatamiz');

        if (_globalAudioHandler != null) {
          _audioHandler = _globalAudioHandler;
          _audioPlayer = _audioHandler!.player;
          _isInitialized = true;

          // ✅ Stream subscriptions ni sozlash
          _setupStreamSubscriptions();

           _initAudioPlayer();
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio playerni ishga tushirishda xatolik: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // ✅ Har qanday holatda ham loading ni to'xtatish
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ Stream subscriptions ni sozlash
  void _setupStreamSubscriptions() {
    // Duration stream
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer?.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Position stream
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer?.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = position;
        });
      }
    });

    // Player state stream
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          // Loading faqat buffering yoki loading holatida true bo'ladi
          if (state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering) {
            _isLoading = true;
          } else if (state.processingState == ProcessingState.ready ||
              state.processingState == ProcessingState.completed) {
            _isLoading = false;
          }
        });
      }
    });

    // Current index stream
    _currentIndexSubscription?.cancel();
    _currentIndexSubscription = _audioPlayer?.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  void _listenToDownloadProgress() {
    _downloadProgressSubscription = _backgroundDownloader.progressStream.listen((progress) {
      if (progress.bookId == widget.data.id && mounted) {
        setState(() {
          _downloadProgress = progress.progress;

          if (progress.status == DownloadStatus.completed) {
            _isDownloading = false;
            _isDownloaded = true;
          } else if (progress.status == DownloadStatus.failed) {
            _isDownloading = false;
          } else if (progress.status == DownloadStatus.downloading) {
            _isDownloading = true;
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App background ga ketganda pozitsiyani saqlash
      _saveCurrentPosition();
    } else if (state == AppLifecycleState.resumed) {
      // App qaytib kelganda oxirgi tinglangan vaqtni yangilash
      AudioPositionService.saveLastPlayed(widget.data.id);
    }
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await _downloadManager.isBookDownloaded(widget.data.id);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  void _initAudioPlayer() async {
    debugPrint('🔵 4. Audio Player ni sozlash...');

    if (_audioPlayer == null) {
      debugPrint('❌ Audio player is null!');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      debugPrint('🔵 5. MediaItem list yaratish...');

      // MediaItem listini yaratish
      final List<audio_service_pkg.MediaItem> mediaItems = [];

      // ✅ Har bir content va har bir file uchun MediaItem yaratish
      for (var content in widget.data.contents) {
        debugPrint('📁 Content: ${content.name}, Files: ${content.files.length}');

        for (var file in content.files) {
          // ✅ URL ni tekshirish va validatsiya
          String audioUrl = file.file.trim();

          if (audioUrl.isEmpty) {
            debugPrint('⚠️ Bo\'sh URL topildi: ${content.name}');
            continue;
          }

          // ✅ URL format tekshirish
          if (!audioUrl.startsWith('http://') &&
              !audioUrl.startsWith('https://') &&
              !audioUrl.startsWith('file://')) {
            debugPrint('⚠️ Noto\'g\'ri URL format: $audioUrl');
            continue;
          }

          final mediaItem = audio_service_pkg.MediaItem(
            id: audioUrl,
            title: content.name,
            artist: widget.data.author.fullName,
            album: widget.data.title,
            artUri: Uri.tryParse(widget.data.coverImage),
            duration: Duration.zero,
            extras: {
              'fileId': file.id,
              'contentName': content.name,
            },
          );

          mediaItems.add(mediaItem);
          debugPrint('✅ MediaItem yaratildi: ${content.name} - File ID: ${file.id}');
        }
      }

      if (mediaItems.isEmpty) {
        throw Exception('Valid audio fayllar topilmadi!');
      }

      debugPrint('✅ Jami ${mediaItems.length} ta MediaItem yaratildi');

      // AudioHandler ga playlist yuklash
      if (_isInitialized && _audioHandler != null) {
        debugPrint('🔵 6. AudioHandler ga playlist yuklash...');

        try {
          await (_audioHandler as AudioPlayerHandler).initPlaylist(mediaItems);
          debugPrint('✅ Playlist muvaffaqiyatli yuklandi');

          // ✅ Playlist yuklanganini kutish
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e, stackTrace) {
          debugPrint('❌ Playlist yuklashda xatolik: $e');
          debugPrint('StackTrace: $stackTrace');
          throw e;
        }
      }

      // SAQLANGAN POZITSIYANI YUKLASH
      debugPrint('🔵 7. Saqlangan pozitsiyani yuklash...');
      final savedData = await AudioPositionService.getPosition(widget.data.id);
      final savedPosition = Duration(seconds: savedData['position']!);
      final savedIndex = savedData['index']!;

      // ✅ Index va pozitsiyani tekshirish
      if (savedIndex >= 0 && savedIndex < mediaItems.length) {
        if (savedPosition.inSeconds > 5) {
          debugPrint('⏩ Saqlangan pozitsiyaga o\'tish: ${_formatDuration(savedPosition)}');

          // ✅ Pozitsiyaga o'tishdan oldin biroz kutish
          await Future.delayed(Duration(milliseconds: 800));

          try {
            await _audioPlayer!.seek(savedPosition, index: savedIndex);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.history_rounded, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Oxirgi tinglangan joydan davom ettirilmoqda (${_formatDuration(savedPosition)})',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Boshidan',
                    textColor: Colors.white,
                    onPressed: () {
                      _audioPlayer?.seek(Duration.zero, index: 0);
                      AudioPositionService.clearPosition(widget.data.id);
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('⚠️ Seek error (ignored): $e');
          }
        }
      }

      // ✅ Loading ni to'xtatish
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint('✅ Audio player muvaffaqiyatli sozlandi!');

    } catch (e, stackTrace) {
      debugPrint("❌ Audio player init error: $e");
      debugPrint("StackTrace: $stackTrace");

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio yuklanmadi: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Oxirgi pozitsiyani saqlash
    _saveCurrentPosition();
    AudioPositionService.saveLastPlayed(widget.data.id);

    // Timer ni to'xtatish
    _positionSaveTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _downloadProgressSubscription?.cancel();

    // ⚠️ AudioHandler ni to'xtatmaslik (boshqa ekranlarda ham ishlashi uchun)
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_audioPlayer == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio ijro etishda xatolik: $e')),
        );
      }
    }
  }

  void _seekToPosition(double value) {
    if (_audioPlayer == null) return;
    final position = Duration(seconds: value.toInt());
    _audioPlayer!.seek(position);
    // Seek qilinganda ham pozitsiyani saqlash
    Future.delayed(Duration(milliseconds: 500), () {
      _saveCurrentPosition();
    });
  }

  void _changeSpeed(double speed) {
    if (_audioPlayer == null) return;
    setState(() {
      _playbackSpeed = speed;
    });
    _audioPlayer!.setSpeed(speed);
  }

  void _skipForward() {
    if (_audioPlayer == null) return;
    final newPosition = _position + Duration(seconds: 10);
    if (newPosition < _duration) {
      _audioPlayer!.seek(newPosition);
    } else {
      _audioPlayer!.seek(_duration);
    }
    _saveCurrentPosition();
  }

  void _skipBackward() {
    if (_audioPlayer == null) return;
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _audioPlayer!.seek(newPosition);
    } else {
      _audioPlayer!.seek(Duration.zero);
    }
    _saveCurrentPosition();
  }

  void _skipToNext() {
    if (_audioPlayer == null) return;
    if (_audioPlayer!.hasNext) {
      _audioPlayer!.seekToNext();
      _saveCurrentPosition();
    }
  }

  void _skipToPrevious() {
    if (_audioPlayer == null) return;
    if (_audioPlayer!.hasPrevious) {
      _audioPlayer!.seekToPrevious();
      _saveCurrentPosition();
    }
  }

  void _toggleLoopMode() {
    if (_audioPlayer == null) return;
    setState(() {
      switch (_loopMode) {
        case LoopMode.off:
          _loopMode = LoopMode.one;
          break;
        case LoopMode.one:
          _loopMode = LoopMode.all;
          break;
        case LoopMode.all:
          _loopMode = LoopMode.off;
          break;
      }
    });
    _audioPlayer!.setLoopMode(_loopMode);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  // Current chapter name olish
  String _getCurrentChapterName() {
    if (_currentIndex >= 0) {
      int fileCount = 0;
      for (var content in widget.data.contents) {
        for (var i = 0; i < content.files.length; i++) {
          if (fileCount == _currentIndex) {
            return content.name;
          }
          fileCount++;
        }
      }
    }
    return widget.data.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Text(widget.data.title),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            _buildBookCover(widget.data.coverImage),
            SizedBox(height: 24.h),

            // Chapter name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                _getCurrentChapterName(),
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 8.h),

            // Author name
            Text(
              widget.data.author.fullName,
              style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
            ),

            Spacer(),

            // Progress slider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.grey.withOpacity(0.3),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                      trackHeight: 3.h,
                    ),
                    child: Slider(
                      value: _duration.inSeconds > 0
                          ? _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble())
                          : 0.0,
                      max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      onChangeStart: (value) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _position = Duration(seconds: value.toInt());
                        });
                      },
                      onChangeEnd: (value) {
                        _seekToPosition(value);
                        setState(() {
                          _isDragging = false;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // Control buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous track button
                  IconButton(
                    onPressed: (_audioPlayer?.hasPrevious ?? false) ? _skipToPrevious : null,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: (_audioPlayer?.hasPrevious ?? false) ? AppColors.black : AppColors.grey,
                      size: 36.sp,
                    ),
                  ),

                  // Backward 10s
                  IconButton(
                    onPressed: _audioPlayer != null ? _skipBackward : null,
                    icon: Icon(
                      Icons.replay_10_rounded,
                      color: _audioPlayer != null ? AppColors.black : AppColors.grey,
                      size: 32.sp,
                    ),
                  ),

                  // Play/Pause button
                  _isLoading
                      ? SizedBox(
                    width: 64.sp,
                    height: 64.sp,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  )
                      : GestureDetector(
                    onTap: _audioPlayer != null ? _togglePlayPause : null,
                    child: Container(
                      width: 64.sp,
                      height: 64.sp,
                      decoration: BoxDecoration(
                        color: _audioPlayer != null ? AppColors.primary : AppColors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_audioPlayer != null ? AppColors.primary : AppColors.grey).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36.sp,
                      ),
                    ),
                  ),

                  // Forward 10s
                  IconButton(
                    onPressed: _audioPlayer != null ? _skipForward : null,
                    icon: Icon(
                      Icons.forward_10_rounded,
                      color: _audioPlayer != null ? AppColors.black : AppColors.grey,
                      size: 32.sp,
                    ),
                  ),

                  // Next track button
                  IconButton(
                    onPressed: (_audioPlayer?.hasNext ?? false) ? _skipToNext : null,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: (_audioPlayer?.hasNext ?? false) ? AppColors.black : AppColors.grey,
                      size: 36.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Secondary controls
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Volume button
                  IconButton(
                    onPressed: () => _showVolumeDialog(),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.grey,
                      size: 24.sp,
                    ),
                  ),

                  // Loop mode button
                  IconButton(
                    onPressed: _toggleLoopMode,
                    icon: Icon(
                      _loopMode == LoopMode.off
                          ? Icons.repeat_rounded
                          : _loopMode == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_on_rounded,
                      color: _loopMode == LoopMode.off ? AppColors.grey : AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 11.sp),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        onTap: (index) {
          switch (index) {
            case 0:
              _showChaptersList();
              break;
            case 1:
              _showSpeedDialog();
              break;
            case 2:
              _showDownloadDialog();
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_rounded),
            label: "Bo'limlar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: "${_playbackSpeed}x",
          ),
          BottomNavigationBarItem(
            icon: _isDownloading
                ? SizedBox(
              width: 24.sp,
              height: 24.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _downloadProgress,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : Icon(
              _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
            ),
            label: _isDownloading
                ? "${(_downloadProgress * 100).toInt()}%"
                : _isDownloaded
                ? "Yuklab olingan"
                : "Yuklab olish",
          ),
        ],
      ),
    );
  }

  void _showVolumeDialog() {
    if (_audioPlayer == null) return;

    double volume = 1.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.volume_up_rounded, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text('Ovoz balandligi', style: AppStyle.font600(AppColors.black)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.grey.withOpacity(0.3),
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(volume * 100).round()}%',
                    onChanged: (value) {
                      setDialogState(() {
                        volume = value;
                      });
                      _audioPlayer?.setVolume(value);
                    },
                  ),
                ),
                Text(
                  '${(volume * 100).round()}%',
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppStyle.font600(AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.speed_rounded, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text('Ijro tezligi', style: AppStyle.font600(AppColors.black)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
              title: Text(
                '${speed}x',
                style: AppStyle.font400(AppColors.black),
              ),
              trailing: _playbackSpeed == speed
                  ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : Icon(Icons.circle_outlined, color: AppColors.grey),
              onTap: () {
                _changeSpeed(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showChaptersList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, color: AppColors.primary),
                      SizedBox(width: 8.w),
                      Text(
                        'Bo\'limlar',
                        style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1.h),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.data.contents.length,
                    itemBuilder: (context, index) {
                      final content = widget.data.contents[index];
                      final isCurrentChapter = _getCurrentChapterName() == content.name;

                      return ListTile(
                        leading: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppStyle.font600(
                                isCurrentChapter ? AppColors.primary : AppColors.grey,
                              ),
                            ),
                          ),
                        ),

                        title: Text(
                          content.name,
                          style: AppStyle.font400(
                            isCurrentChapter ? AppColors.primary : AppColors.black,
                          ),
                        ),

                        // ⬇️ YANGI QO‘SHILADI – bo‘lim davomiyligi
                        subtitle: Text(
                          _formatDuration(_duration),
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
                        ),

                        trailing: isCurrentChapter
                            ? Icon(Icons.graphic_eq_rounded, color: AppColors.primary)
                            : null,

                        onTap: () {
                          if (_audioPlayer == null) return;
                          int targetIndex = 0;
                          for (int i = 0; i < index; i++) {
                            targetIndex += widget.data.contents[i].files.length;
                          }
                          _audioPlayer!.seek(Duration.zero, index: targetIndex);
                          _saveCurrentPosition();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDownloadDialog() {
    if (_isDownloading) {
      // Agar yuklab olinayotgan bo'lsa, hech narsa qilmaslik
    } else {
      // Download options ko'rsatish
      _showDownloadOptions();
    }
  }

  void _showDownloadOptions() {
    // Calculate total size
    int totalSize = 0;
    for (var content in widget.data.contents) {
      for (var file in content.files) {
        totalSize += file.size;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text('Yuklab olish', style: AppStyle.font600(AppColors.black)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu audiokitobni yuklab olmoqchimisiz?',
              style: AppStyle.font400(AppColors.black),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.book_rounded, 'Kitob', widget.data.title),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.person_rounded, 'Muallif', widget.data.author.fullName),
            SizedBox(height: 8.h),
            _buildInfoRow(
              Icons.folder_rounded,
              'Bo\'limlar',
              '${widget.data.contents.length} ta',
            ),
            SizedBox(height: 8.h),
            _buildInfoRow(
              Icons.storage_rounded,
              'Hajmi',
              _downloadManager.formatFileSize(totalSize),
            ),
            SizedBox(height: 16.h),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish', style: AppStyle.font400(AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Yuklab olish', style: AppStyle.font600(Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyle.font600(AppColors.black).copyWith(fontSize: 12.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    if (!mounted) return;

    // ✅ 1. Avval permission tekshirish
    debugPrint('🔐 Checking storage permission...');
    final hasPermission = await PermissionHelper.requestStoragePermission(context);

    if (!hasPermission) {
      debugPrint('❌ Storage permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('Storage ruxsati berilmadi!')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Sozlamalar',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return; // Permission yo'q bo'lsa, to'xtatish
    }

    debugPrint('✅ Storage permission granted');

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    // Prepare parts data
    List<Map<String, dynamic>> parts = [];
    for (var content in widget.data.contents) {
      for (var file in content.files) {
        parts.add({
          'id': file.id,
          'name': content.name,
          'url': file.file,
          'size': file.size,
          'format': file.fileFormat,
        });
      }
    }

    debugPrint('📦 Prepared ${parts.length} parts for download');

    // Show notification that download started in background
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text('Yuklab olish boshlandi...'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Start background download
    debugPrint('🚀 Starting background download...');
    final success = await _backgroundDownloader.startDownload(
      bookId: widget.data.id,
      title: widget.data.title,
      format: widget.data.format ?? 'mp3',
      description: widget.data.description ?? '',
      coverImage: widget.data.coverImage,
      audioDuration: 0,
      authorName: widget.data.author.fullName,
      parts: parts,
    );

    debugPrint('📥 Download result: $success');

    // Final status will be updated via stream
    if (!success && mounted) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(child: Text('Yuklab olishda xatolik yuz berdi!')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Qayta',
            textColor: Colors.white,
            onPressed: () => _startDownload(),
          ),
        ),
      );
    }
  }

  Widget _buildBookCover(imgUrl) {
    return Hero(
      tag: 'book_cover_${widget.data.id}',
      child: Container(
        width: 200.w,
        height: 260.h,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              spreadRadius: 8,
              blurRadius: 20,
              offset: Offset(0, 8),
            )
          ],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: CachedNetworkImage(
            imageUrl: imgUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.grey.withOpacity(0.2),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.grey.withOpacity(0.2),
              child: Icon(Icons.book, size: 60.sp, color: AppColors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import 'dart:io';

import 'package:sahhof/src/database/database_helper.dart';
import 'package:sahhof/src/model/audio/audio_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_handler.dart';

class LocalAudioPlayerScreen extends StatefulWidget {
  final int bookId;

  const LocalAudioPlayerScreen({
    Key? key,
    required this.bookId,
  }) : super(key: key);

  @override
  State<LocalAudioPlayerScreen> createState() => _LocalAudioPlayerScreenState();
}

class _LocalAudioPlayerScreenState extends State<LocalAudioPlayerScreen>
    with WidgetsBindingObserver {

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioDownloadManager _downloadManager = AudioDownloadManager();

  AudioPlayer? _audioPlayer;
  AudioPlayerHandler? _audioHandler;
  bool _isInitialized = false;

  // Book data
  DownloadedBookModel? _bookData;
  List<Map<String, dynamic>> _audioParts = [];

  // Player state
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isDragging = false;
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.off;

  // Position save timer
  Timer? _positionSaveTimer;

  // StreamSubscriptions
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _currentIndexSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioService();
    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    _savePlaybackPosition();
    _positionSaveTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();

    if (_isInitialized && _audioHandler != null) {
      _audioHandler!.customAction('dispose');
    } else {
      _audioPlayer?.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Background ga ketganda pozitsiyani saqlash
      _savePlaybackPosition();
    }
  }

  // Auto save timer - har 10 sekundda
  void _startAutoSaveTimer() {
    _positionSaveTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isPlaying && _position.inSeconds > 0) {
        _savePlaybackPosition();
      }
    });
  }

  Future<void> _initAudioService() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Audio Service ni boshlash
      try {
        // Har doim oddiy audio player ishlatamiz, audio service kerak bo'lsa keyinroq qo'shamiz
        _audioPlayer = AudioPlayer();
        _isInitialized = false;

        debugPrint('Using simple AudioPlayer (no background service)');
      } catch (e) {
        debugPrint('Audio service init error: $e');
        _audioPlayer = AudioPlayer();
        _isInitialized = false;
      }

      await _loadLocalAudio();
    } catch (e) {
      debugPrint('Init error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalAudio() async {
    try {
      // Database dan kitob ma'lumotlarini olish
      final book = await _dbHelper.getDownloadedBook(widget.bookId);
      final parts = await _dbHelper.getAudioParts(widget.bookId);
      if (book == null) {
        throw Exception('Kitob topilmadi');
      }

      // Parts ni Map ga convert qilish
      final audioParts = parts.map((part) => {
        'id': part.id,
        'part_id': part.partId,
        'name': part.name,
        'path': part.path,
        'size': part.size,
      }).toList();
      if (audioParts.isEmpty) {
        throw Exception('Audio fayllar topilmadi');
      }

      setState(() {
        _bookData = book;
        _audioParts = audioParts;
      });

      await _initAudioPlayer();

    } catch (e) {
      debugPrint('Error loading local audio: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('Xatolik: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initAudioPlayer() async {
    if (_audioPlayer == null || _bookData == null) {
      debugPrint('Audio player or book data is null');
      return;
    }

    try {
      List<AudioSource> audioSources = [];

      debugPrint('========== CHECKING AUDIO FILES ==========');
      debugPrint('Total parts: ${_audioParts.length}');

      for (int i = 0; i < _audioParts.length; i++) {
        final part = _audioParts[i];
        final filePath = part['path'] as String;
        final file = File(filePath);

        debugPrint('--- Part ${i + 1} ---');
        debugPrint('Name: ${part['name']}');
        debugPrint('Path: $filePath');

        // Fayl mavjudligini tekshirish
        final exists = await file.exists();
        debugPrint('File exists: $exists');

        if (exists) {
          final fileSize = await file.length();
          debugPrint('File size: ${_formatBytes(fileSize)}');
          audioSources.add(
            AudioSource.file(
              filePath,
              tag: {
                'title': part['name'],
                'id': part['id'],
                'part_id': part['part_id'],
              },
            ),
          );
        } else {
          debugPrint('⚠️ FILE NOT FOUND!');

          // Directory ni ham tekshiramiz
          final directory = file.parent;
          final dirExists = await directory.exists();
          debugPrint('Parent directory exists: $dirExists');

          if (dirExists) {
            debugPrint('Files in directory:');
            try {
              final files = directory.listSync();
              for (var f in files) {
                debugPrint('  - ${f.path}');
              }
            } catch (e) {
              debugPrint('Cannot list directory: $e');
            }
          }
        }
      }

      debugPrint('========================================');
      debugPrint('Found ${audioSources.length} valid audio files');

      if (audioSources.isEmpty) {
        throw Exception('Hech qanday audio fayl topilmadi.\n\nFayllar bazada saqlanganmi tekshiring.\n\nYuklab olish jarayonida xatolik bo\'lgan bo\'lishi mumkin.');
      }

      // Oddiy playlist yaratish
      final playlist = ConcatenatingAudioSource(children: audioSources);
      await _audioPlayer!.setAudioSource(playlist);

      // Streams ni sozlash
      _setupAudioStreams();

      // Oxirgi pozitsiyadan davom ettirish
      final lastPosition = _bookData!.lastPlayedPosition;
      if (lastPosition > 5) {
        await _audioPlayer!.seek(Duration(seconds: lastPosition));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.history_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Oxirgi joydan davom ettirilmoqda (${_formatDuration(Duration(seconds: lastPosition))})',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Boshidan',
                textColor: Colors.white,
                onPressed: () {
                  _audioPlayer?.seek(Duration.zero, index: 0);
                  _savePlaybackPosition();
                },
              ),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Error initializing audio player: $e');

      if (mounted) {
        // Show detailed error with action to re-download
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8.w),
                Expanded(child: Text('Xatolik', style: AppStyle.font600(Colors.red))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio fayllar topilmadi.',
                  style: AppStyle.font500(AppColors.black).copyWith(fontSize: 14.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Bu kitobni qaytadan yuklab olishingiz kerak.',
                  style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 13.sp),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: Text('Yopish'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  // Delete broken book
                  await _downloadManager.deleteDownloadedBook(widget.bookId);
                  Navigator.pop(context); // Go back

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kitob o\'chirildi. Qaytadan yuklab oling.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('O\'chirib, qayta yuklash', style: AppStyle.font500(Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _setupAudioStreams() {
    if (_audioPlayer == null) return;

    // Duration stream
    _durationSubscription = _audioPlayer!.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    // Position stream
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      if (!_isDragging && mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Player state stream
    _playerStateSubscription = _audioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        // Pause bo'lganda pozitsiyani saqlash
        if (!state.playing && _position.inSeconds > 0) {
          _savePlaybackPosition();
        }

        // Audio tugaganda
        if (state.processingState == ProcessingState.completed) {
          if (_audioPlayer?.hasNext == false) {
            _savePlaybackPosition();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text('Kitob tugadi!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            _skipToNext();
          }
        }
      }
    });

    // Current index stream
    _currentIndexSubscription = _audioPlayer!.currentIndexStream.listen((index) {
      if (mounted && index != null) {
        setState(() {
          _currentIndex = index;
        });
        _savePlaybackPosition();
      }
    });
  }

  Future<void> _savePlaybackPosition() async {
    if (_bookData == null || _audioPlayer == null) return;

    try {
      await _dbHelper.updateLastPlayedPosition(
        widget.bookId,
        _position.inSeconds,
      );
    } catch (e) {
      debugPrint('Error saving playback position: $e');
    }
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
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    }
  }

  void _seekToPosition(double value) {
    if (_audioPlayer == null) return;
    final position = Duration(seconds: value.toInt());
    _audioPlayer!.seek(position);
    Future.delayed(Duration(milliseconds: 500), () {
      _savePlaybackPosition();
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
    _savePlaybackPosition();
  }

  void _skipBackward() {
    if (_audioPlayer == null) return;
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _audioPlayer!.seek(newPosition);
    } else {
      _audioPlayer!.seek(Duration.zero);
    }
    _savePlaybackPosition();
  }

  void _skipToNext() {
    if (_audioPlayer == null) return;
    if (_audioPlayer!.hasNext) {
      _audioPlayer!.seekToNext();
      _savePlaybackPosition();
    }
  }

  void _skipToPrevious() {
    if (_audioPlayer == null) return;
    if (_audioPlayer!.hasPrevious) {
      _audioPlayer!.seekToPrevious();
      _savePlaybackPosition();
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
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20.h),
              Text(
                'Yuklanmoqda...',
                style: AppStyle.font500(AppColors.black).copyWith(fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          title: Text('Yuklab olingan audio'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 80.sp, color: Colors.red),
              SizedBox(height: 20.h),
              Text(
                'Kitob topilmadi',
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _bookData!.title,
          style: AppStyle.font600(Colors.black).copyWith(fontSize: 16.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _showPlaylistDialog,
            icon: Icon(Icons.queue_music_rounded, color: Colors.black),
            tooltip: 'Playlist',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showBookInfo();
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Ma\'lumot'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20.sp, color: Colors.red),
                    SizedBox(width: 12.w),
                    Text('O\'chirish', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // Cover image
            Hero(
              tag: 'local_book_cover_${widget.bookId}',
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
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: _bookData!.coverImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.grey.withOpacity(0.2),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.grey.withOpacity(0.2),
                      child: Icon(Icons.audiotrack_rounded, size: 60.sp, color: AppColors.grey),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                _getCurrentPartName(),
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 8.h),

            // Author
            Text(
              _bookData!.authorName,
              style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
            ),

            SizedBox(height: 16.h),

            // Current part info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Qism ${_currentIndex + 1}/${_audioParts.length}',
                style: AppStyle.font500(AppColors.primary).copyWith(fontSize: 14.sp),
              ),
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
                  // Previous
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

                  // Play/Pause
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

                  // Next
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
                  // Speed
                  IconButton(
                    onPressed: _showSpeedDialog,
                    icon: Row(
                      children: [
                        Icon(Icons.speed_rounded, color: AppColors.grey, size: 24.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${_playbackSpeed}x',
                          style: AppStyle.font500(AppColors.grey).copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),

                  // Loop mode
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
    );
  }

  String _getCurrentPartName() {
    if (_currentIndex >= 0 && _currentIndex < _audioParts.length) {
      return _audioParts[_currentIndex]['name'];
    }
    return _bookData?.title ?? '';
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text(
                  'Ijro tezligi',
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                final isSelected = _playbackSpeed == speed;
                return InkWell(
                  onTap: () {
                    _changeSpeed(speed);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80.w,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${speed}x',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  void _showPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: AppColors.primary),
                  SizedBox(width: 12.w),
                  Text(
                    'Bo\'limlar (${_audioParts.length} ta)',
                    style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _audioParts.length,
                  itemBuilder: (context, index) {
                    final part = _audioParts[index];
                    final isPlaying = _currentIndex == index;

                    return Card(
                      color: isPlaying ? AppColors.primary.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: isPlaying ? AppColors.primary : AppColors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: isPlaying
                                ? Icon(Icons.graphic_eq_rounded, color: Colors.white)
                                : Text(
                              '${index + 1}',
                              style: AppStyle.font600(AppColors.grey),
                            ),
                          ),
                        ),
                        title: Text(
                          part['name'],
                          style: AppStyle.font400(
                            isPlaying ? AppColors.primary : AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatBytes(part['size'] ?? 0),
                          style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                        ),
                        trailing: isPlaying
                            ? Icon(Icons.play_arrow_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          _audioPlayer?.seek(Duration.zero, index: index);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookInfo() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text(
                  'Kitob haqida',
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildInfoRow(Icons.book_rounded, 'Nomi', _bookData!.title),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.person_rounded, 'Muallif', _bookData!.authorName),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.audiotrack_rounded, 'Qismlar', '${_audioParts.length} ta'),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.storage_rounded, 'Hajmi', _bookData!.formattedSize),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 12.w),
        Text(
          '$label: ',
          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyle.font600(AppColors.black).copyWith(fontSize: 14.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(child: Text('O\'chirish', style: AppStyle.font600(Colors.orange))),
          ],
        ),
        content: Text(
          'Kitobni va barcha audio fayllarni o\'chirmoqchimisiz?',
          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('O\'chirish', style: AppStyle.font500(AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBook();
    }
  }

  Future<void> _deleteBook() async {
    await _savePlaybackPosition();
    await _audioPlayer?.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final success = await _downloadManager.deleteDownloadedBook(widget.bookId);

      Navigator.pop(context); // Close loading

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text('Kitob o\'chirildi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context);
        }
      } else {
        throw Exception('O\'chirishda xatolik');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
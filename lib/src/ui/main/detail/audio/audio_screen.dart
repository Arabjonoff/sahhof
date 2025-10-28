import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart' hide DownloadProgress;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';
import 'package:sahhof/src/ui/main/detail/audio/simple_download.dart';
import 'dart:async';

import '../../../../model/book/book_detail.dart';
import 'audio_handler.dart' show AudioPlayerHandler;
import '../../../../theme/app_colors.dart';
// import 'audio_download_manager.dart';
// import 'database_helper.dart';
// import 'simple_background_downloader.dart';

class AudioScreen extends StatefulWidget {
  final BookDetailModel data;
  const AudioScreen({super.key, required this.data});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _checkDownloadStatus();
    _listenToDownloadProgress();
  }
  late AudioPlayerHandler _audioHandler;

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.yourapp.audio',
        androidNotificationChannelName: 'Audio Playback',
      ),
    );
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
      // App background ga ketganda
      _audioPlayer.pause();
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
    try {
      setState(() {
        _isLoading = true;
      });

      // Playlist yaratish
      final playlist = ConcatenatingAudioSource(
        children: widget.data.contents.expand((content) {
          return content.files.map((file) {
            return AudioSource.uri(
              Uri.parse(file.file),
              tag: {
                'title': content.name,
                'id': file.id,
              },
            );
          });
        }).toList(),
      );

      // Audio fayllarni yuklash
      await _audioPlayer.setAudioSource(playlist);

      // Duration stream
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      // Position stream
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (!_isDragging && mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Player state stream
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });

          // Audio tugaganda keyingisiga o'tish
          if (state.processingState == ProcessingState.completed) {
            _skipToNext();
          }
        }
      });

      // Current index stream (qaysi track ijro bo'layotganini bilish uchun)
      _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
        if (mounted && index != null) {
          setState(() {
            _currentIndex = index;
          });
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio yuklashda xatolik: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _downloadProgressSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
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
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

  void _skipForward() {
    final newPosition = _position + Duration(seconds: 10);
    if (newPosition < _duration) {
      _audioPlayer.seek(newPosition);
    } else {
      _audioPlayer.seek(_duration);
    }
  }

  void _skipBackward() {
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _audioPlayer.seek(newPosition);
    } else {
      _audioPlayer.seek(Duration.zero);
    }
  }

  void _skipToNext() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    }
  }

  void _skipToPrevious() {
    if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
    }
  }

  void _toggleLoopMode() {
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
    _audioPlayer.setLoopMode(_loopMode);
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
    if (_currentIndex >= 0 && _currentIndex < widget.data.contents.length) {
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
                    onPressed: _audioPlayer.hasPrevious ? _skipToPrevious : null,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: _audioPlayer.hasPrevious ? AppColors.black : AppColors.grey,
                      size: 36.sp,
                    ),
                  ),

                  // Backward 10s
                  IconButton(
                    onPressed: _skipBackward,
                    icon: Icon(
                      Icons.replay_10_rounded,
                      color: AppColors.black,
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
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 64.sp,
                      height: 64.sp,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
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
                    onPressed: _skipForward,
                    icon: Icon(
                      Icons.forward_10_rounded,
                      color: AppColors.black,
                      size: 32.sp,
                    ),
                  ),

                  // Next track button
                  IconButton(
                    onPressed: _audioPlayer.hasNext ? _skipToNext : null,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: _audioPlayer.hasNext ? AppColors.black : AppColors.grey,
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
            case 3:
              _showBookmarkDialog();
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
              _isDownloaded
                  ? Icons.download_done_rounded
                  : Icons.download_rounded,
            ),
            label: _isDownloading
                ? "${(_downloadProgress * 100).toInt()}%"
                : _isDownloaded
                ? "Yuklab olingan"
                : "Yuklab olish",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline_rounded),
            label: "Belgilash",
          ),
        ],
      ),
    );
  }

  void _showVolumeDialog() {
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
                      _audioPlayer.setVolume(value);
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
                        trailing: isCurrentChapter
                            ? Icon(Icons.graphic_eq_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          // Skip to this chapter
                          int targetIndex = 0;
                          for (int i = 0; i < index; i++) {
                            targetIndex += widget.data.contents[i].files.length;
                          }
                          _audioPlayer.seek(Duration.zero, index: targetIndex);
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
    if (_isDownloaded) {
      // Show delete confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 8.w),
              Text('O\'chirish', style: AppStyle.font600(AppColors.black)),
            ],
          ),
          content: Text(
            'Bu audiokitobni o\'chirmoqchimisiz?',
            style: AppStyle.font400(AppColors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Bekor qilish', style: AppStyle.font400(AppColors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteBook();
              },
              child: Text('O\'chirish', style: AppStyle.font600(Colors.red)),
            ),
          ],
        ),
      );
    } else if (_isDownloading) {
      // Show cancel confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.orange),
              SizedBox(width: 8.w),
              Text('Bekor qilish', style: AppStyle.font600(AppColors.black)),
            ],
          ),
          content: Text(
            'Yuklab olishni bekor qilmoqchimisiz?',
            style: AppStyle.font400(AppColors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Yo\'q', style: AppStyle.font400(AppColors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Cancel download logic here
              },
              child: Text('Ha', style: AppStyle.font600(Colors.orange)),
            ),
          ],
        ),
      );
    } else {
      // Show download dialog
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

    // Show notification that download started in background
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
              child: Text('Yuklab olish boshlandi....'),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // Start background download
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

  Widget _buildDownloadProgressDialog() {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button during download
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text('Yuklab olinmoqda...', style: AppStyle.font600(AppColors.black)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            // Listen to progress updates
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setDialogState(() {});
              }
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80.w,
                        height: 80.w,
                        child: CircularProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: AppColors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 6,
                        ),
                      ),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                        style: AppStyle.font600(AppColors.black).copyWith(fontSize: 20.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: AppColors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Iltimos, kuting...',
                  style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Yuklab olinmoqda',
                  style: AppStyle.font400(AppColors.black).copyWith(fontSize: 14.sp),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteBook() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _downloadManager.deleteDownloadedBook(widget.data.id);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isDownloaded = !success;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Text('O\'chirildi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Text('O\'chirishda xatolik!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showBookmarkDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Belgilash funksiyasi tez orada qo\'shiladi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
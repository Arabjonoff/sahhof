import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

import 'package:sahhof/src/database/database_helper.dart';
import 'package:sahhof/src/model/audio/audio_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';

class LocalAudioPlayerScreen extends StatefulWidget {
  final int bookId; // Database dan o'qish uchun

  const LocalAudioPlayerScreen({
    Key? key,
    required this.bookId,
  }) : super(key: key);

  @override
  State<LocalAudioPlayerScreen> createState() => _LocalAudioPlayerScreenState();
}

class _LocalAudioPlayerScreenState extends State<LocalAudioPlayerScreen>
    with WidgetsBindingObserver {

  // UNCOMMENT qiling
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioDownloadManager _downloadManager = AudioDownloadManager();

  late AudioPlayer _audioPlayer;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _loadLocalAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    }
  }

  Future<void> _loadLocalAudio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // UNCOMMENT qiling - Database dan kitob ma'lumotlarini olish
      final book = await _dbHelper.getDownloadedBook(widget.bookId);
      final parts = await _dbHelper.getAudioParts(widget.bookId);

      // Test uchun:
      // final book = {
      //   'id': 1,
      //   'book_id': widget.bookId,
      //   'title': 'Test Kitob',
      //   'author_name': 'Test Muallif',
      //   'cover_image': 'https://example.com/cover.jpg',
      //   'audio_duration': 3600,
      //   'total_size': 50000000,
      //   'formatted_size': '50 MB',
      //   'formatted_duration': '01:00:00',
      // };
      // final parts = <Map<String, dynamic>>[];

      if (book == null) {
        throw Exception('Kitob topilmadi');
      }

      // UNCOMMENT qiling - Parts ni Map ga convert qilish
      final audioParts = parts.map((part) => {
        'id': part.id,
        'part_id': part.partId,
        'name': part.name,
        'path': part.path,
        'size': part.size,
      }).toList();

      // final audioParts = parts; // Test uchun

      if (audioParts.isEmpty) {
        throw Exception('Audio fayllar topilmadi');
      }

      setState(() {
        _bookData = book;
        _audioParts = audioParts;
      });

      await _initAudioPlayer();

    } catch (e) {
      print('Error loading local audio: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Xatolik: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back if error
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
    try {
      // Local fayllarni tekshirish
      List<AudioSource> audioSources = [];

      for (var part in _audioParts) {
        final filePath = part['path'] as String;
        final file = File(filePath);

        // Fayl mavjudligini tekshirish
        if (await file.exists()) {
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
          print('File not found: $filePath');
        }
      }

      if (audioSources.isEmpty) {
        throw Exception('Hech qanday audio fayl topilmadi');
      }

      // Playlist yaratish
      final playlist = ConcatenatingAudioSource(children: audioSources);

      // Audio source ni set qilish
      await _audioPlayer.setAudioSource(playlist);

      // Streams ni sozlash
      _setupAudioStreams();

      // Last played position dan davom ettirish (agar mavjud bo'lsa)
      final lastPosition = _bookData!.lastPlayedPosition;
      if (lastPosition > 0) {
        await _audioPlayer.seek(Duration(seconds: lastPosition));
      }

    } catch (e) {
      print('Error initializing audio player: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _setupAudioStreams() {
    // Duration stream
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    // Position stream
    _audioPlayer.positionStream.listen((position) {
      if (!_isDragging && mounted) {
        setState(() {
          _position = position;
        });

        // Har 30 sekundda position ni saqlash
        if (position.inSeconds % 30 == 0) {
          _savePlaybackPosition();
        }
      }
    });

    // Player state stream
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        // Audio tugaganda
        if (state.processingState == ProcessingState.completed) {
          _skipToNext();
        }
      }
    });

    // Current index stream
    _audioPlayer.currentIndexStream.listen((index) {
      if (mounted && index != null) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  Future<void> _savePlaybackPosition() async {
    if (_bookData == null) return;

    try {
      // UNCOMMENT qiling
      await _dbHelper.updateLastPlayedPosition(
        widget.bookId,
        _position.inSeconds,
      );
    } catch (e) {
      print('Error saving playback position: $e');
    }
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
          SnackBar(content: Text('Xatolik: $e')),
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
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20.sp),
              Text(
                'Yuklanmoqda...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text('Local Audio Player'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 80, color: Colors.red),
              SizedBox(height: 20.sp),
              Text(
                'Kitob topilmadi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _bookData!.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showPlaylistDialog,
            icon: Icon(Icons.queue_music_rounded, color: Colors.white),
            tooltip: 'Playlist',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.white),
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
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Ma\'lumot'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('O\'chirish', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue,
                  Colors.blue.withOpacity(0.1),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(
              children: [
                // Cover image
                Hero(
                  tag: 'book_cover_${widget.bookId}',
                  child: Container(
                    width: 200,
                    height: 250.sp,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 8,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _bookData!.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.audiotrack_rounded, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.sp),

                // Title
                Text(
                  _bookData!.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8),

                // Author
                Text(
                  _bookData!.authorName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.sp),

                // Current track info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.audiotrack_rounded, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Qism ${_currentIndex + 1}/${_audioParts.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Player controls
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.sp,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Colors.blue,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: Colors.blue,
                          overlayColor: Colors.blue.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _position.inSeconds.toDouble(),
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _isDragging = true;
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
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.sp),

                  // Main controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Previous
                      IconButton(
                        onPressed: _audioParts.length > 1 ? _skipToPrevious : null,
                        icon: Icon(Icons.skip_previous_rounded),
                        iconSize: 40,
                        color: Colors.grey[700],
                      ),

                      // Backward 10s
                      IconButton(
                        onPressed: _skipBackward,
                        icon: Icon(Icons.replay_10_rounded),
                        iconSize: 36,
                        color: Colors.grey[700],
                      ),

                      // Play/Pause
                      Container(
                        width: 70,
                        height: 70.sp,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 36,
                        ),
                      ),

                      // Forward 10s
                      IconButton(
                        onPressed: _skipForward,
                        icon: Icon(Icons.forward_10_rounded),
                        iconSize: 36,
                        color: Colors.grey[700],
                      ),

                      // Next
                      IconButton(
                        onPressed: _audioParts.length > 1 ? _skipToNext : null,
                        icon: Icon(Icons.skip_next_rounded),
                        iconSize: 40,
                        color: Colors.grey[700],
                      ),
                    ],
                  ),


                  // Secondary controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Speed
                      _buildControlButton(
                        icon: Icons.speed_rounded,
                        label: '${_playbackSpeed}x',
                        onPressed: _showSpeedDialog,
                      ),

                      // Loop mode
                      _buildControlButton(
                        icon: _loopMode == LoopMode.off
                            ? Icons.repeat_rounded
                            : _loopMode == LoopMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_on_rounded,
                        label: _loopMode == LoopMode.off
                            ? 'O\'chiriq'
                            : _loopMode == LoopMode.one
                            ? 'Bitta'
                            : 'Hammasi',
                        onPressed: _toggleLoopMode,
                        isActive: _loopMode != LoopMode.off,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue : Colors.grey[700],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.blue : Colors.grey[700],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Tezlikni tanlang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: AppColors.black),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                final isSelected = _playbackSpeed == speed;
                return InkWell(
                  onTap: () {
                    _changeSpeed(speed);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${speed}x',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.sp),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.sp,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20.sp),
              Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: Colors.blue),
                  SizedBox(width: 12),
                  Text(
                    'Playlist (${_audioParts.length} ta)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: AppColors.black),
                  ),
                ],
              ),
              SizedBox(height: 20.sp),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _audioParts.length,
                  itemBuilder: (context, index) {
                    final part = _audioParts[index];
                    final isPlaying = _currentIndex == index;

                    return Card(
                      color: isPlaying ? Colors.blue.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40.sp,
                          decoration: BoxDecoration(
                            color: isPlaying ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isPlaying
                                ? Icon(Icons.play_arrow_rounded, color: Colors.white)
                                : Text(
                              '${index + 1}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        title: Text(
                          part['name'],
                          style: TextStyle(
                            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                            color: isPlaying ? Colors.blue : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatBytes(part['size'] ?? 0),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: isPlaying
                            ? Icon(Icons.equalizer_rounded, color: Colors.blue)
                            : null,
                        onTap: () {
                          _audioPlayer.seek(Duration.zero, index: index);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Kitob haqida',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 24.sp),
            _buildInfoRow(Icons.book_rounded, 'Nomi', _bookData!.title),
            SizedBox(height: 16.sp),
            _buildInfoRow(Icons.person_rounded, 'Muallif', _bookData!.authorName),
            SizedBox(height: 16.sp),
            _buildInfoRow(Icons.audiotrack_rounded, 'Qismlar', '${_audioParts.length} ta'),
            SizedBox(height: 16.sp),
            _buildInfoRow(Icons.storage_rounded, 'Hajmi', _bookData!.formattedSize),
            SizedBox(height: 16.sp),
            _buildInfoRow(Icons.timer_rounded, 'Davomiyligi', _bookData!.formattedDuration),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('O\'chirish',style: AppStyle.font600(Colors.orange),)),
          ],
        ),
        content: Text(
          'Kitobni va barcha audio fayllarni o\'chirmoqchimisiz?',
          style: TextStyle(fontSize: 14,color: AppColors.grey),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('O\'chirish',style: AppStyle.font500(AppColors.white),),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBook();
    }
  }

  Future<void> _deleteBook() async {
    // Save current position before deleting
    await _savePlaybackPosition();

    // Pause player
    await _audioPlayer.pause();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Colors.blue),
      ),
    );

    try {
      // UNCOMMENT qiling
      final success = await _downloadManager.deleteDownloadedBook(widget.bookId);
      // final success = true; // Test uchun

      Navigator.pop(context); // Close loading

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Kitob o\'chirildi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Go back
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
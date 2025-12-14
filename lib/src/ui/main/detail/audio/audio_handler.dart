import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();

  // Playlist holati
  bool _isPlaylistLoaded = false;

  AudioPlayerHandler() {
    // Player state changes ni AudioService ga ulash
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Current item changes
    player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Player errors ni handle qilish
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.idle && !state.playing) {
        print('⚠️ Player idle state');
      }
    });
  }

  // ✅ Playlist ni yuklash (AudioScreen dan chaqiriladi)
  Future<void> initPlaylist(List<MediaItem> items) async {
    try {
      print('🔵 Starting initPlaylist with ${items.length} items');

      // ✅ 1. Items validatsiyasi
      if (items.isEmpty) {
        throw Exception('MediaItem list bo\'sh!');
      }

      // ✅ 2. Har bir item URLni tekshirish
      final validItems = <MediaItem>[];
      for (var item in items) {
        if (item.id.isEmpty) {
          print('⚠️ Bo\'sh URL topildi, o\'tkazib yuboriladi: ${item.title}');
          continue;
        }

        // URL formatini tekshirish
        if (!item.id.startsWith('http://') &&
            !item.id.startsWith('https://') &&
            !item.id.startsWith('file://')) {
          print('⚠️ Noto\'g\'ri URL format: ${item.id}');
          continue;
        }

        print('✅ Valid URL: ${item.id}');
        validItems.add(item);
      }

      if (validItems.isEmpty) {
        throw Exception('Hech qanday valid audio URL topilmadi!');
      }

      print('✅ ${validItems.length} ta valid MediaItem topildi');

      // ✅ 3. Queue ni yangilash
      queue.add(validItems);

      // ✅ 4. Eski audio ni to'xtatish
      if (_isPlaylistLoaded) {
        print('⏸️ Eski playlistni to\'xtatish...');
        try {
          await player.stop();
          await Future.delayed(Duration(milliseconds: 200));
        } catch (e) {
          print('⚠️ Stop error (ignored): $e');
        }
      }

      // ✅ 5. Audio sources yaratish
      print('🔵 Audio sources yaratmoqda...');
      final audioSources = <AudioSource>[];

      for (var item in validItems) {
        try {
          final source = AudioSource.uri(
            Uri.parse(item.id),
            tag: item,
          );
          audioSources.add(source);
          print('✅ Audio source yaratildi: ${item.title}');
        } catch (e) {
          print('❌ Audio source yaratishda xatolik: ${item.id} - $e');
        }
      }

      if (audioSources.isEmpty) {
        throw Exception('Hech qanday audio source yaratilmadi!');
      }

      // ✅ 6. Playlist yaratish va yuklash
      print('🔵 Playlist yaratmoqda va yuklanmoqda...');

      try {
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          shuffleOrder: DefaultShuffleOrder(),
          children: audioSources,
        );

        await player.setAudioSource(
          playlist,
          initialIndex: 0,
          initialPosition: Duration.zero,
        );

        print('✅ Playlist muvaffaqiyatli yuklandi: ${audioSources.length} ta audio');
      } catch (e, stackTrace) {
        print('❌ Playlist yuklashda xatolik: $e');
        print('StackTrace: $stackTrace');

        // Xatolik haqida batafsil ma'lumot
        if (e.toString().contains('Unable to connect')) {
          print('❌ Internet ulanishi yo\'q yoki server javob bermayapti');
        } else if (e.toString().contains('404')) {
          print('❌ Audio fayl topilmadi (404)');
        } else if (e.toString().contains('403')) {
          print('❌ Audio faylga kirish taqiqlangan (403)');
        }

        throw Exception('Audio yuklashda xatolik: $e');
      }

      // ✅ 7. Birinchi itemni set qilish
      if (validItems.isNotEmpty) {
        mediaItem.add(validItems[0]);
      }

      _isPlaylistLoaded = true;

      print('✅ initPlaylist tugadi, jami ${validItems.length} ta audio');

    } catch (e, stackTrace) {
      print('❌ initPlaylist da xatolik: $e');
      print('StackTrace: $stackTrace');

      // ✅ Xatolik holatini tozalash
      _isPlaylistLoaded = false;
      queue.add([]);

      // Xatolikni qayta throw qilish
      throw Exception('Playlist yuklashda xatolik: $e');
    }
  }

  // PlaybackState ni transform qilish
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: player.currentIndex,
    );
  }

  // ========================================
  // AUDIO SERVICE METHODS
  // ========================================

  @override
  Future<void> play() async {
    try {
      await player.play();
    } catch (e) {
      print('❌ Play error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await player.pause();
    } catch (e) {
      print('❌ Pause error: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await player.stop();
      _isPlaylistLoaded = false;
      await super.stop();
    } catch (e) {
      print('❌ Stop error: $e');
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
    } catch (e) {
      print('❌ Seek error: $e');
      rethrow;
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      if (player.hasNext) {
        await player.seekToNext();
      }
    } catch (e) {
      print('❌ Skip to next error: $e');
      rethrow;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (player.hasPrevious) {
        await player.seekToPrevious();
      }
    } catch (e) {
      print('❌ Skip to previous error: $e');
      rethrow;
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      if (index >= 0 && index < queue.value.length) {
        await player.seek(Duration.zero, index: index);
      }
    } catch (e) {
      print('❌ Skip to queue item error: $e');
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await player.setSpeed(speed);
    } catch (e) {
      print('❌ Set speed error: $e');
      rethrow;
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          await player.setLoopMode(LoopMode.off);
          break;
        case AudioServiceRepeatMode.one:
          await player.setLoopMode(LoopMode.one);
          break;
        case AudioServiceRepeatMode.all:
          await player.setLoopMode(LoopMode.all);
          break;
        case AudioServiceRepeatMode.group:
          await player.setLoopMode(LoopMode.all);
          break;
      }
    } catch (e) {
      print('❌ Set repeat mode error: $e');
      rethrow;
    }
  }

  // Dispose
  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
    } catch (e) {
      print('❌ onTaskRemoved error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await player.dispose();
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }
}
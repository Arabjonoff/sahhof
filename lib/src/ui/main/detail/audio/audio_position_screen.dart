import 'package:shared_preferences/shared_preferences.dart';

class AudioPositionService {
  static const String _keyPrefix = 'audio_position_';
  static const String _keyCurrentIndex = 'audio_current_index_';

  // Pozitsiyani saqlash
  static Future<void> savePosition(
      int bookId,
      Duration position,
      int currentIndex,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}$bookId', position.inSeconds);
    await prefs.setInt('${_keyCurrentIndex}$bookId', currentIndex);
  }

  // Pozitsiyani o'qish
  static Future<Map<String, int>> getPosition(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final positionSeconds = prefs.getInt('${_keyPrefix}$bookId') ?? 0;
    final currentIndex = prefs.getInt('${_keyCurrentIndex}$bookId') ?? 0;

    return {
      'position': positionSeconds,
      'index': currentIndex,
    };
  }

  // Pozitsiyani o'chirish (kitob tugaganda)
  static Future<void> clearPosition(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}$bookId');
    await prefs.remove('${_keyCurrentIndex}$bookId');
  }

  // Barcha kitoblarning oxirgi tinglan vaqtini saqlash
  static Future<void> saveLastPlayed(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_played_$bookId', DateTime.now().millisecondsSinceEpoch);
  }

  // Oxirgi tinglan vaqtni olish
  static Future<DateTime?> getLastPlayed(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_played_$bookId');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
}
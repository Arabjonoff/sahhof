import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class CacheService {
  static SharedPreferences? preferences;

  static init() async {
    preferences = await SharedPreferences.getInstance();
  }

  static Future<bool> clear() async {
    return await preferences!.clear();
  }

  /// device info
  static void saveDeviceInfo(Map<String, dynamic> deviceData) {
    final msg = jsonEncode(deviceData);
    preferences!.setString("deviceData", msg);
  }

  static String getDeviceInfo() {
    return preferences!.getString("deviceData") ?? "";
  }

  /// onboard
  static void saveOnboard(bool data) {
    preferences!.setBool("first_login", data);
  }

  static bool getOnboard() {
    bool data = preferences!.getBool("first_login") ?? false;
    return data;
  }

  /// language
  static void saveLanguage(String language) {
    preferences!.setString("language", language);
  }

  static String getLanguage() {
    String language = preferences!.getString("language") ?? "uz";
    return language;
  }

  /// Token
  static void saveToken(String data) {
    preferences!.setString("token", data);
  }
  static void refreshToken(String data) {
    preferences!.setString("refresh_token", data);
  }

  static String getToken() {
    String data = preferences!.getString("token") ?? "";
    return data;
  }

  /// user id
  static void saveUserId(int data) {
    preferences!.setInt("user_id", data);
  }

  static int getUserId() {
    int data = preferences!.getInt("user_id") ?? 0;
    return data;
  }

  /// save balance
  static void saveBalance(int data) {
    preferences!.setInt("user_id", data);
  }

  static int getBalance() {
    int data = preferences!.getInt("user_id") ?? 0;
    return data;
  }

  /// login
  static void saveLogin(String data) {
    preferences!.setString("user_login", data);
  }

  static String getLogin() {
    String data = preferences!.getString("user_login") ?? "";
    return data;
  }

  /// avatar
  static void saveAvatar(String data) {
    preferences!.setString("user_avatar", data);
  }

  static String getAvatar() {
    String data = preferences!.getString("user_avatar") ?? "";
    return data;
  }

  /// first name
  static void saveUserFirstName(String data) {
    preferences!.setString("user_first_name", data);
  }

  static String getUserFirstName() {
    String data = preferences!.getString("user_first_name") ?? "";
    return data;
  }

  /// last name
  static void saveUserLastName(String data) {
    preferences!.setString("user_last_name", data);
  }

  static String getUserLastName() {
    String data = preferences!.getString("user_last_name") ?? "";
    return data;
  }

  /// gender
  static void saveGender(String data) {
    preferences!.setString("gender", data);
  }

  static String getGender() {
    String data = preferences!.getString("gender") ?? "";
    return data;
  }

  /// birth_date
  static void saveBirthDate(String data) {
    preferences!.setString("birth_date", data);
  }

  static String getBirthDate() {
    String data = preferences!.getString("birth_date") ?? "";
    return data;
  }

  /// region_name
  static void saveRegionName(String data) {
    preferences!.setString("region_name", data);
  }

  static String getRegionName() {
    String data = preferences!.getString("region_name") ?? "";
    return data;
  }

  /// region id
  static void saveRegionId(int data) {
    preferences!.setInt("region_id", data);
  }

  static int getRegionId() {
    int data = preferences!.getInt("region_id") ?? 1;
    return data;
  }
}

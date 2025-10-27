import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:http/http.dart'as http;
import 'package:sahhof/src/utils/cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiProvider{
  Duration durationTimeout = const Duration(seconds: 30);
  String baseUrl = "http://buxoro-sf.uz/";

  getReqHeader() {
    String token = CacheService.getToken();
    if (token == "") {
      return {
        "Accept": "application/json",
      };
    } else {
      return {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };
    }
  }

  Future<HttpResult> postRequest(url, body) async {
    if (kDebugMode) {
      print(url);
      print(body);
    }

    final dynamic headers = await getReqHeader();
    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: body,
      )
          .timeout(durationTimeout);
      return result(response);
    } on TimeoutException catch (_) {
      return HttpResult(
        isSuccess: false,
        status: -1,
        result: null,
      );
    } on SocketException catch (_) {
      return HttpResult(
        isSuccess: false,
        status: -1,
        result: null,
      );
    }
  }
  Future<HttpResult> patchRequest(url, body) async {
    if (kDebugMode) {
      print(url);
      print(body);
    }

    final dynamic headers = await getReqHeader();
    try {
      http.Response response = await http
          .patch(
        Uri.parse(url),
        headers: headers,
        body: body,
      )
          .timeout(durationTimeout);
      return result(response);
    } on TimeoutException catch (_) {
      return HttpResult(
        isSuccess: false,
        status: -1,
        result: null,
      );
    } on SocketException catch (_) {
      return HttpResult(
        isSuccess: false,
        status: -1,
        result: null,
      );
    }
  }


  Future<HttpResult> getRequest(String url) async {
    final headers = await getReqHeader();

    if (kDebugMode) {
      print("🔹 REQUEST URL: $url");
      print("🔹 REQUEST HEADERS: $headers");
    }

    try {
      http.Response response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(durationTimeout);

      if (response.statusCode == 401 || _isTokenInvalid(response)) {
        print("⚠️ Token eskirgan, refresh qilinmoqda...");
        bool refreshed = await _refreshToken();

        if (refreshed) {
          final newHeaders = await getReqHeader();
          response = await http
              .get(Uri.parse(url), headers: newHeaders)
              .timeout(durationTimeout);
        } else {
          print("❌ Token yangilash muvaffaqiyatsiz bo‘ldi.");
        }
      }
      return result(response);
    } on TimeoutException catch (_) {
      return HttpResult(isSuccess: false, status: -1, result: "Timeout");
    } on SocketException catch (_) {
      return HttpResult(isSuccess: false, status: -1, result: "No Internet");
    }
  }
  HttpResult result(http.Response response) {
    if (kDebugMode) {
      print(response.body);
    }
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return HttpResult(
        isSuccess: true,
        status: response.statusCode,
        result: json.decode(utf8.decode(response.bodyBytes)),
      );
    } else {
      try {
        return HttpResult(
          isSuccess: false,
          status: response.statusCode,
          result: json.decode(utf8.decode(response.bodyBytes)),
        );
      } catch (_) {
        return HttpResult(
          isSuccess: false,
          status: response.statusCode,
          result: response.body,
        );
      }
    }
  }
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString("refresh_token");
      if (refreshToken == null) return false;
      final response = await http.post(
        Uri.parse("${baseUrl}api/token/refresh/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refreshToken}),
      );
      print("refreshToken: $refreshToken");
      print("response: ${response.body}");
      print("response: ${response.request}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data["access"];
        if (newAccess != null) {
          CacheService.saveToken(newAccess);
          await prefs.setString("access", newAccess);
          return true;
        }
      }
      print("⚠️ Token yangilashda xato: ${response.body}");
      return false;
    } catch (e) {
      print("❌ _refreshToken xato: $e");
      return false;
    }
  }
  bool _isTokenInvalid(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map &&
          body.containsKey("code") &&
          body["code"] == "token_not_valid") {
        return true;
      }
    } catch (_) {}
    return false;
  }



  Future<HttpResult> register(Map data)async{
    String url = "${baseUrl}api/v1/auth/register/";
    return await postRequest(url, data);
  }
  Future<HttpResult> login(Map data)async{
    String url = "${baseUrl}api/v1/auth/login/";
    return await postRequest(url, data);
  }
  Future<HttpResult> logout()async{
    String url = "${baseUrl}api/v1/auth/delete/account";
    return await getRequest(url);
  }
  Future<HttpResult> verification(int id,code)async{
    String url = "${baseUrl}api/v1/auth/activate/$id/";
    return await postRequest(url, {"activation_code": code});
  }
  Future<HttpResult> changePassword(data)async{
    String url = "${baseUrl}api/v1/auth/change-password/";
    return await patchRequest(url, data);
  }
  Future<HttpResult> resetPassword(data)async{
    String url = "${baseUrl}api/v1/auth/password-reset/";
    return await postRequest(url, data);
  }

  Future<HttpResult> getCategories()async{
    String url = "${baseUrl}api/v1/categories/";
    return await getRequest(url,);
  }
  Future<HttpResult> getBooks(id)async{
    String url = "${baseUrl}api/v1/books/?category__id=$id";
    if(id == 0){
      url = "${baseUrl}api/v1/books/";
    }else{
      url = "${baseUrl}api/v1/books/?category__id=$id";
    }
    return await getRequest(url,);
  }
  Future<HttpResult> getBookById(int id)async{
    String url = "${baseUrl}api/v1/books/$id/";
    return await getRequest(url,);
  }
  Future<HttpResult> addCommentRating(int id,data)async{
    String url = "${baseUrl}api/v1/books/$id/add_rating/";
    return await postRequest(url,data);
  }
  Future<HttpResult> addBookMark(int id)async{
    String url = "${baseUrl}api/v1/books/$id/add_saved_book/";
    return await postRequest(url,{
      "property1": "null",
      "property2": "null"
    });
  }

  Future<HttpResult> getBookMark()async{
    String url = "${baseUrl}api/v1/auth/saved-books/";
    return await getRequest(url);
  }
  Future<HttpResult> getBanner()async{
    String url = "${baseUrl}api/v1/banners/";
    return await getRequest(url);
  }
  Future<HttpResult> getProfile()async{
    String url = "${baseUrl}api/v1/auth/me/";
    return await getRequest(url);
  }

  Future<HttpResult> pdfDownload(id)async{
    String url = "${baseUrl}api/v1/books/$id/pdf_download/";
    return await getRequest(url);
  }
  Future<HttpResult> audioDownload(id)async{
    String url = "${baseUrl}api/v1/books/$id/audio_download/";
    return await getRequest(url);
  }
  Future<HttpResult> getAuthors()async{
    String url = "${baseUrl}api/v1/authors/";
    return await getRequest(url);
  }
  Future<HttpResult> getAuthorById(int id)async{
    String url = "${baseUrl}api/v1/authors/$id/";
    return await getRequest(url);
  }

}
























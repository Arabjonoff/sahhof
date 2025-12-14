import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/bloc/book/book_bloc.dart';
import 'package:sahhof/src/bloc/book/book_detail_bloc.dart';
import 'package:sahhof/src/model/book/book_detail.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_screen.dart';
import 'package:sahhof/src/ui/main/detail/comment/comment_screen.dart';
import 'package:sahhof/src/ui/main/detail/read/read_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
import 'package:sahhof/src/widget/button_widget.dart';
import 'package:http/http.dart' as http;

import '../../auth/register_screen.dart';

class DetailScreen extends StatefulWidget {
  final int id;

  const DetailScreen({super.key, required this.id});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final Repository _repository = Repository();
  BookDetailModel bookDetailModel = BookDetailModel.fromJson({});
  bool savedBook = false;
  StreamSubscription? _downloadSubscription;
  String? downloadedPdfPath;
  bool isCheckingDownload = true;

  @override
  void initState() {
    super.initState();
    bookDetailBloc.getBookDetail(widget.id);
    bookBloc.getBooks(0);
  }

  Future<void> _checkIfPdfDownloaded(String title) async {
    if (!isCheckingDownload) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$title.pdf');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            downloadedPdfPath = file.path;
            isCheckingDownload = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            downloadedPdfPath = null;
            isCheckingDownload = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          downloadedPdfPath = null;
          isCheckingDownload = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookDetailModel>(
        stream: bookDetailBloc.getBookDetailStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data!;
            bookDetailModel = snapshot.data!;
            savedBook = data.userData.savedBook;
            if (isCheckingDownload) {
              _checkIfPdfDownloaded(data.title);
            }

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text("Kitoblar"),
                backgroundColor: Colors.white,
                actions: [
                  IconButton(
                    onPressed: () {
                      _repository.addBookMark(widget.id);
                      bookDetailBloc.getBookDetail(widget.id);

                    },
                    icon: Icon(
                      savedBook
                          ? Icons.bookmark
                          : Icons.bookmark_outline_rounded,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBookCover(data.coverImage),
                          SizedBox(height: 24.h),
                          Center(
                            child: Text(data.title,
                                style: AppStyle.font600(AppColors.black)),
                          ),
                          SizedBox(height: 8.h),
                          Center(
                            child: Text(data.author.fullName,
                                style: AppStyle.font400(AppColors.grey)),
                          ),
                          const Divider(),
                          _buildInfoRow(data),
                          const Divider(),
                          Text("Kitob haqida",
                              style: AppStyle.font800(AppColors.black)),
                          SizedBox(height: 8.h),
                          Text(
                            data.description,
                            style: AppStyle.font500(AppColors.black),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "Izohlar",
                              style: AppStyle.font600(AppColors.black),
                            ),
                          ),
                          SizedBox(
                            height: 180.sp,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.comments.length,
                                itemBuilder: (ctx, index) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16.h, horizontal: 16.sp),
                                    margin: EdgeInsets.only(right: 16.w),
                                    width: 300.sp,
                                    height: 180.sp,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColors.greyAccent,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 50.sp,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                width: 48.sp,
                                                height: 48.sp,
                                                decoration: BoxDecoration(
                                                  color: AppColors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(Icons.person),
                                              ),
                                              SizedBox(
                                                width: 16.w,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 8,
                                                      child: ListView.builder(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          physics:
                                                              NeverScrollableScrollPhysics(),
                                                          shrinkWrap: true,
                                                          itemCount: data
                                                              .comments[index]
                                                              .stars,
                                                          itemBuilder:
                                                              (ctx, index) {
                                                            return Icon(
                                                              Icons.star,
                                                              color: AppColors
                                                                  .orange,
                                                              size: 16.sp,
                                                            );
                                                          }),
                                                    ),
                                                    SizedBox(
                                                      height: 15,
                                                    ),
                                                    Text(
                                                      data.comments[index].user
                                                          .username,
                                                      style: AppStyle.font400(
                                                          AppColors.black),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: 16.w,
                                              ),
                                              Text(
                                                DateFormat('yyyy-MM-dd').format(
                                                    data.comments[index]
                                                        .createdAt),
                                                style: AppStyle.font400(
                                                    AppColors.black),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 16.h,
                                        ),
                                        Text(
                                          data.comments[index].comment,
                                          style:
                                              AppStyle.font400(AppColors.black),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                          ),
                          SizedBox(
                            height: 16.h,
                          ),
                          ButtonWidget(
                              text: "Kitob haqida izoh qoldirish",
                              textColor: AppColors.blue,
                              backgroundColor: AppColors.white,
                              onTap: () {
                                if(CacheService.getToken().isEmpty){
                                  Navigator.push(context, MaterialPageRoute(builder: (builder){
                                    return RegisterScreen();
                                  }));
                                }
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (ctx) {
                                  return CommentScreen(
                                    id: data.id,
                                  );
                                }));
                              }),
                          SizedBox(
                            height: 16.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(context, data),
                ],
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        });
  }

  Widget _buildBookCover(String imageUrl) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 280.h,
          width: 200.w,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(secs)}';
    }
  }


  Widget _buildInfoRow(BookDetailModel data) {
    final items = [
      (
        data.audio_duration == 0 ? "Sahifalar" : "Davomiligi",
        Text(
            "${data.audio_duration == 0 ? data.pdf_total_pages : formatDuration(data.audio_duration)}",
            style: AppStyle.font800(AppColors.black))
      ),
      ("Til", Text(data.language, style: AppStyle.font800(AppColors.black))),
      ("Ovoz", Text("${data.voice}", style: AppStyle.font800(AppColors.black))),
      (
        "Reyting",
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: AppColors.orange, size: 16.sp),
            SizedBox(width: 4.w),
            Text("${data.rating}", style: AppStyle.font800(AppColors.black)),
          ],
        )
      ),
    ];

    return SizedBox(
      height: 60.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        separatorBuilder: (_, __) => Container(
          width: 1.w,
          height: 30.h,
          color: AppColors.grey,
          margin: EdgeInsets.symmetric(horizontal: 12.w),
        ),
        itemBuilder: (context, index) {
          final title = items[index].$1;
          final value = items[index].$2;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppStyle.font500(AppColors.grey)),
              SizedBox(height: 4.h),
              value,
            ],
          );
        },
      ),
    );
  }
  Widget _buildBottomButtons(BuildContext context, BookDetailModel data) {
    print("🔍 BUILD BOTTOM BUTTONS:");
    print("   Format: ${bookDetailModel.format}");
    print("   Downloaded path: $downloadedPdfPath");
    print("   Is checking: $isCheckingDownload");

    return Container(
      margin: EdgeInsets.only(bottom: 34.h, left: 16.w, right: 16.w, top: 16.h),
      height: 56.h,
      child: Row(
        children: [
          // AUDIO TUGMASI
          if (bookDetailModel.format == "AUDIO")
            Expanded(
              child: GestureDetector(
                onTap: () {
                  print("🎵 Audio tugmasi bosildi");
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                    return AudioScreen(data: bookDetailModel);
                  }));
                },
                child: _buildButton(
                  color: AppColors.blue,
                  textColor: Colors.white,
                  icon: Icons.play_circle_outline_rounded,
                  text: "Audio",
                  filled: true,
                ),
              ),
            ),

          if (bookDetailModel.format == "AUDIO" && bookDetailModel.format == "PDF")
            SizedBox(width: 16.w),

          // PDF TUGMALARI
          if (bookDetailModel.format == "PDF")
            Expanded(
              child: downloadedPdfPath != null
                  ? GestureDetector(
                onTap: () {
                  print("📖 O'qish tugmasi bosildi: $downloadedPdfPath");
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                    return ReadScreen(
                      pdfPath: downloadedPdfPath!,
                      bookTitle: bookDetailModel.title,
                    );
                  }));
                },
                child: _buildButton(
                  color: AppColors.blue,
                  textColor: Colors.white,
                  icon: Icons.chrome_reader_mode,
                  text: "O'qish",
                  filled: true,
                ),
              )
                  : GestureDetector(
                onTap: () {
                  print("📥 YUKLAB OLISH TUGMASI BOSILDI!");
                  print("   URL: http://buxoro-sf.uz/api/v1/books/${bookDetailModel.id}/pdf_download/");
                  print("   Fayl: ${bookDetailModel.title}.pdf");

                  try {
                    _showDownloadDialog(context);
                    print("✅ Dialog ochildi");
                  } catch (e) {
                    print("❌ Dialog ochishda xato: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Xato: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: _buildButton(
                  color: AppColors.blue,
                  textColor: AppColors.blue,
                  icon: Icons.download_rounded,
                  text: "Yuklab olish",
                  filled: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
  void _showDownloadDialog(BuildContext context) {
    print("\n🚀 === YUKLAB OLISH BOSHLANDI ===");

    final url = 'http://buxoro-sf.uz/api/v1/books/${bookDetailModel.id}/pdf_download/';

    print("📋 Ma'lumotlar:");
    print("   ID: ${bookDetailModel.id}");
    print("   URL: $url");
    print("   Fayl: ${bookDetailModel.title}.pdf");
    print("   Context: ${context != null ? 'OK' : 'NULL'}");

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          print("✅ Dialog builder ishga tushdi");
          return _DownloadProgressDialog(
            url: url,
            fileName: bookDetailModel.title,
            onDownloadComplete: (file) async {
              print("✅ Yuklab olish tugadi: ${file.path}");
              Navigator.of(dialogContext).pop();

              if (!mounted) {
                print("⚠️ Widget mounted emas");
                return;
              }

              setState(() {
                downloadedPdfPath = file.path;
              });

              await _repository.insertPdf(
                bookDetailModel.title,
                DateTime.now().toString(),
                bookDetailModel.author.fullName,
                bookDetailModel.coverImage,
                file.lengthSync(),
                file.path,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ Yuklab olindi"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                  action: SnackBarAction(
                    label: "O'qish",
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReadScreen(
                            bookTitle: bookDetailModel.title,
                            pdfPath: file.path,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            onError: (error) {
              print("❌ Xato yuz berdi: $error");
              Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Xato: $error"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
          );
        },
      );
      print("✅ showDialog chaqirildi");
    } catch (e, stackTrace) {
      print("❌ KRITIK XATO:");
      print("   Xato: $e");
      print("   Stack: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Dialog ochishda xato: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
  Widget _buildButton({
    required Color color,
    required Color textColor,
    required IconData icon,
    required String text,
    bool filled = true,
  }) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 18),
          SizedBox(width: 6.w),
          Text(text,
              style: AppStyle.font600(textColor).copyWith(fontSize: 13.sp)),
        ],
      ),
    );
  }
}

// Alohida StatefulWidget progress dialog uchun
class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final Function(File) onDownloadComplete;
  final Function(String) onError;

  const _DownloadProgressDialog({
    required this.url,
    required this.fileName,
    required this.onDownloadComplete,
    required this.onError,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  StreamSubscription? _downloadSubscription;
  bool _isDownloading = true;
  String _downloadedSize = "0 MB";
  String _totalSize = "0 MB";
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _client?.close();
    super.dispose();
  }

  void _startDownload() async {
    try {
      // 1. Fayl yo‘lini yaratish
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.fileName}.pdf');
      if (await file.exists()) await file.delete(); // Avvalgisini o‘chirish

      // 2. http.Client yaratish
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      request.headers.addAll({
        'Authorization': 'Bearer ${CacheService.getToken()}',
      });
      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        _safeError('Server xatosi: ${response.statusCode}');
        return;
      }

      final contentLength = response.contentLength ?? 0;
      if (contentLength == 0) {
        _safeError('Fayl hajmi aniqlanmadi');
        return;
      }

      // 4. Faylga yozish
      final sink = file.openWrite();
      int bytesReceived = 0;

      _safeSetState(() {
        _totalSize = _formatBytes(contentLength);
      });

      // 5. Har bir chunkda progress yangilash
      _downloadSubscription = response.stream.listen(
        (chunk) {
          if (!mounted) return;

          bytesReceived += chunk.length;
          sink.add(chunk);

          final progress = bytesReceived / contentLength;
          final downloadedSize = _formatBytes(bytesReceived);

          _safeSetState(() {
            _progress = progress;
            _downloadedSize = downloadedSize;
          });
        },
        onDone: () async {
          await sink.close();
          if (mounted) {
            _safeSetState(() => _isDownloading = false);
            widget.onDownloadComplete(file);
          }
        },
        onError: (e) async {
          await sink.close();
          _safeError(e.toString());
        },
        cancelOnError: true,
      );
    } catch (e) {
      _safeError(e.toString());
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _safeError(String message) {
    if (mounted) {
      _safeSetState(() => _isDownloading = false);
      widget.onError(message);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isDownloading,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.blue),
            SizedBox(width: 8.w),
            Text("Yuklanmoqda...", style: AppStyle.font600(AppColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "${(_progress * 100).toStringAsFixed(1)}%",
              style:
                  AppStyle.font800(AppColors.black).copyWith(fontSize: 24.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              "$_downloadedSize / $_totalSize",
              style: AppStyle.font400(AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

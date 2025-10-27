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
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_screen.dart';
import 'package:sahhof/src/ui/main/detail/comment/comment_screen.dart';
import 'package:sahhof/src/ui/main/detail/read/read_screen.dart';
import 'package:sahhof/src/widget/book_card_widget.dart';
import 'package:sahhof/src/widget/button_widget.dart';
import 'package:sahhof/src/widget/shimmer_widget.dart';
import 'package:http/http.dart'as http;

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
          if(snapshot.hasData) {
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
                      savedBook?Icons.bookmark:Icons.bookmark_outline_rounded,
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
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                          Text(data.description,
                            style: AppStyle.font500(AppColors.black),
                          ),
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Izohlar",style: AppStyle.font600(AppColors.black),),
                              trailing: TextButton(onPressed: (){}, child: Text("Barcha izohlar"))
                          ),
                          SizedBox(
                            height: 180.sp,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.comments.length,
                                itemBuilder: (ctx,index){
                                  return Container(
                                    padding: EdgeInsets.symmetric(vertical: 16.h,horizontal: 16.sp),
                                    margin: EdgeInsets.only(right: 16.w),
                                    width: 300.sp,
                                    height: 180.sp,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColors.greyAccent,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 50.sp,
                                          width: MediaQuery.of(context).size.width,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 48.sp,
                                                height: 48.sp,
                                                decoration: BoxDecoration(
                                                  color: AppColors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              SizedBox(width: 16.w,),
                                              Expanded(child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: 8,
                                                    child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        physics: NeverScrollableScrollPhysics(),
                                                        shrinkWrap: true,
                                                        itemCount: data.comments[index].stars,
                                                        itemBuilder: (ctx,index){
                                                          return Icon(Icons.star,color: AppColors.orange,size: 16.sp,);
                                                        }),
                                                  )
                                                ],
                                              ),),
                                              SizedBox(width: 16.w,),
                                              Text(DateFormat('yyyy-MM-dd').format(data.comments[index].createdAt),style: AppStyle.font400(AppColors.black),)
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 16.h,),
                                        Text(data.comments[index].comment,style: AppStyle.font400(AppColors.black),)
                                      ],
                                    ),
                                  );
                                }),
                          ),
                          SizedBox(height: 16.h,),
                          ButtonWidget(text: "Kitob haqida izoh qoldirish", textColor: AppColors.blue, backgroundColor: AppColors.white, onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (ctx){
                              return CommentScreen(id: data.id,);
                            }));
                          }),
                          SizedBox(height: 16.h,),
                          // SizedBox(
                          //     height: 140.sp,
                          //     child: StreamBuilder<List<BookResult>>(
                          //         stream: bookBloc.getBookStream,
                          //         builder: (context, snapshot) {
                          //           if(snapshot.hasData) {
                          //             var data = snapshot.data!;
                          //             return ListView.builder(
                          //                 scrollDirection: Axis.horizontal,
                          //                 itemCount: data.length,
                          //                 itemBuilder: (ctx,index){
                          //                   return GestureDetector(
                          //                       onTap: (){
                          //                         Navigator.push(context, MaterialPageRoute(builder: (ctx){
                          //                           return DetailScreen(id: data[index].id);
                          //                         }));
                          //                       },
                          //                       child: BookWidget(result: data[index])
                          //                   );
                          //                 });
                          //           }
                          //           return ListView.builder(
                          //               scrollDirection: Axis.horizontal,
                          //               itemCount: 7,
                          //               itemBuilder: (ctx,index){
                          //                 return ShimmerWidget();
                          //               });
                          //         }
                          //     )
                          // ),
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

  Widget _buildInfoRow(BookDetailModel data) {
    final items = [
      ("Sahifalar", Text("${data.title}", style: AppStyle.font800(AppColors.black))),
      ("Til", Text(data.title, style: AppStyle.font800(AppColors.black))),
      ("O'quvchilar", Text("${data.title}", style: AppStyle.font800(AppColors.black))),
      (
      "Reyting",
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppColors.orange, size: 16.sp),
          SizedBox(width: 4.w),
          Text("${data.title}", style: AppStyle.font800(AppColors.black)),
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
    return Container(
      margin: EdgeInsets.only(bottom: 34.h, left: 16.w, right: 16.w, top: 16.h),
      height: 56.h,
      child: Row(
        children: [
          bookDetailModel.format == "AUDIO" ? Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (ctx){
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
          ) : SizedBox(),
          SizedBox(width: 16.w),
          bookDetailModel.format == "PDF" ? Expanded(
            child: Row(
              children: [
                // Online o'qish tugmasi
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Online stream qilib o'qish
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                        return ReadScreen(
                          bookTitle: bookDetailModel.title,
                          pdfUrl: bookDetailModel.id, // URL stream orqali
                        );
                      }));
                    },
                    child: _buildButton(
                      color: AppColors.blue,
                      textColor: Colors.white,
                      icon: Icons.cloud_outlined,
                      text: "Online",
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Yuklab olish / Offline o'qish tugmasi
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (downloadedPdfPath != null) {
                        // Offline o'qish - yuklab olingan fayldan
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                          return ReadScreen(
                            pdfPath: downloadedPdfPath!,
                            bookTitle: bookDetailModel.title,
                          );
                        }));
                      } else {
                        // Yuklab olish
                        _showDownloadDialog(context);
                      }
                    },
                    child: _buildButton(
                      color: downloadedPdfPath != null ? AppColors.primary : AppColors.blue,
                      textColor: downloadedPdfPath != null ? Colors.white : AppColors.blue,
                      icon: downloadedPdfPath != null
                          ? Icons.check_circle_outline
                          : Icons.download_rounded,
                      text: downloadedPdfPath != null ? "Offline" : "Yuklab olish",
                      filled: downloadedPdfPath != null,
                    ),
                  ),
                ),
              ],
            ),
          ) : SizedBox(),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    final url = 'http://buxoro-sf.uz/api/v1/books/${bookDetailModel.id}/pdf_download/';
    final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
    bool isDownloading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            if (isDownloading) {
              final shouldCancel = await showDialog<bool>(
                context: dialogContext,
                builder: (ctx) => AlertDialog(
                  title: Text("Yuklab olishni bekor qilasizmi?"),
                  content: Text("Yuklab olish jarayoni to'xtatiladi"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Yo'q"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Ha"),
                    ),
                  ],
                ),
              );

              if (shouldCancel == true) {
                _downloadSubscription?.cancel();
                return true;
              }
              return false;
            }
            return true;
          },
          child: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return AlertDialog(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text("Yuklanmoqda...", style: AppStyle.font600(AppColors.primary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    downloadPdfWithProgress(
      url: url,
      fileName: bookDetailModel.title,
      onProgress: (value) {
        if (progressNotifier.value != value) {
          progressNotifier.value = value;
        }
      },
      onComplete: (file) {
        isDownloading = false;
        Navigator.pop(context);

        setState(() {
          downloadedPdfPath = file.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Yuklab olindi"),
            action: SnackBarAction(
              label: "O'qish",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                  return ReadScreen(
                    bookTitle: bookDetailModel.title,
                    pdfPath: file.path,
                  );
                }));
              },
            ),
          ),
        );
      },
      onError: (error) {
        isDownloading = false;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Xato: $error")),
        );
      },
    );
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
          Text(text, style: AppStyle.font600(textColor).copyWith(fontSize: 13.sp)),
        ],
      ),
    );
  }

  Future<void> downloadPdfWithProgress({
    required String url,
    required String fileName,
    required void Function(double progress) onProgress,
    required void Function(File file) onComplete,
    required void Function(Object error) onError,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName.pdf');
        final sink = file.openWrite();

        int bytesReceived = 0;

        _downloadSubscription = response.stream.listen(
              (chunk) {
            bytesReceived += chunk.length;
            sink.add(chunk);

            if (contentLength != 0) {
              double progress = bytesReceived / contentLength;
              onProgress(progress);
            }
          },
          onDone: () async {
            await sink.close();

            // Fayl hajmini olish
            final fileSize = await file.length();

            // Bazaga saqlash
            _repository.insertPdf(
              fileName,                              // title
              DateTime.now().toString(),             // download_date
              bookDetailModel.author.fullName,       // author
              bookDetailModel.coverImage,            // cover_image
              fileSize,                              // size (bytes)
              file.path,                             // path
            );

            onComplete(file);
            _downloadSubscription = null;
          },
          onError: (e) {
            sink.close();
            onError(e);
            _downloadSubscription = null;
          },
          cancelOnError: true,
        );
      } else {
        throw Exception('Yuklab olishda xato: ${response.statusCode}');
      }
    } catch (e) {
      onError(e);
    }
  }
}
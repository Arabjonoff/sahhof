import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_screen.dart';

class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, mediaSnapshot) {
        if (!mediaSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final mediaItem = mediaSnapshot.data!;

        return StreamBuilder<PlaybackState>(
          stream: AudioService.playbackStateStream,
          builder: (context, stateSnapshot) {
            if (!stateSnapshot.hasData) return const SizedBox.shrink();

            final state = stateSnapshot.data!;
            final isPlaying = state.playing;

            return Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    // Book cover
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => AudioScreen(data: mediaItem), // moslashtirishingiz kerak
                    //       ),
                    //     );
                    //   },
                    //   child: Container(
                    //     width: 60.w,
                    //     height: 60.h,
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: ClipRRect(
                    //       borderRadius: BorderRadius.circular(8),
                    //       child: CachedNetworkImage(
                    //         imageUrl: mediaItem.artUri.toString(),
                    //         fit: BoxFit.cover,
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    SizedBox(width: 12.w),

                    // Book info
                    // Expanded(
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) => AudioScreen(data: mediaItem),
                    //         ),
                    //       );
                    //     },
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Text(
                    //           mediaItem.title,
                    //           style: AppStyle.font600(AppColors.black).copyWith(fontSize: 14.sp),
                    //           maxLines: 1,
                    //           overflow: TextOverflow.ellipsis,
                    //         ),
                    //         SizedBox(height: 4.h),
                    //         Text(
                    //           mediaItem.artist ?? "",
                    //           style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
                    //           maxLines: 1,
                    //           overflow: TextOverflow.ellipsis,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    // Control buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => AudioService.skipToPrevious(),
                          icon: Icon(
                            Icons.skip_previous,
                            color: AppColors.black,
                            size: 24.sp,
                          ),
                        ),
                        IconButton(
                          onPressed: () => AudioService.play(),
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.primary,
                            size: 32.sp,
                          ),
                        ),
                        IconButton(
                          onPressed: () => AudioService.skipToNext(),
                          icon: Icon(
                            Icons.skip_next,
                            color: AppColors.black,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

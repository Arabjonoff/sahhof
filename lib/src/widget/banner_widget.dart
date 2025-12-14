import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sahhof/src/model/banner/banner_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';

class AnimatedBannerWidget extends StatefulWidget {
  final List<BannerModel> bannerItems;
  final Duration autoPlayDuration;
  final Duration animationDuration;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedBannerWidget({
    Key? key,
    required this.bannerItems,
    this.autoPlayDuration = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 500),
    this.height = 200.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AnimatedBannerWidget> createState() => _AnimatedBannerWidgetState();
}

class _AnimatedBannerWidgetState extends State<AnimatedBannerWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  bool _isAutoPlaying = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startAutoPlay();
    _animationController.forward();
  }

  void _startAutoPlay() {
    if (widget.bannerItems.length > 1 && _isAutoPlaying) {
      Future.delayed(widget.autoPlayDuration, () {
        if (mounted && _isAutoPlaying) {
          _nextPage();
          _startAutoPlay();
        }
      });
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.bannerItems.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0;
    }
    _pageController.animateToPage(
      _currentIndex,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _goToPage(int index) {
    setState(() {
      _currentIndex = index;
      _isAutoPlaying = false;
    });
    _pageController.animateToPage(
      index,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );

    // Auto-play ni qayta boshlash
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isAutoPlaying = true;
        });
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Stack(
          children: [
            // Banner rasmlar
            FadeTransition(
              opacity: _fadeAnimation,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.bannerItems.length,
                itemBuilder: (context, index) {
                  return _BannerItemWidget(
                    item: widget.bannerItems[index],
                  );
                },
              ),
            ),


            // Gradient overlay (text uchun)
            if (widget.bannerItems[_currentIndex].text.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),

            // Text overlay
            // if (widget.bannerItems[_currentIndex].text.isNotEmpty)
            //   Positioned(
            //     bottom: 20,
            //     left: 16,
            //     right: 16,
            //     child: AnimatedSwitcher(
            //       duration: const Duration(milliseconds: 300),
            //       child: Text(
            //         widget.bannerItems[_currentIndex].text,
            //         key: ValueKey(_currentIndex),
            //         style: const TextStyle(
            //           color: Colors.grey,
            //           fontSize: 16,
            //           fontWeight: FontWeight.w600,
            //           shadows: [
            //             Shadow(
            //               offset: Offset(0, 1),
            //               blurRadius: 3,
            //               color: Colors.black54,
            //             ),
            //           ],
            //         ),
            //         textAlign: TextAlign.center,
            //         maxLines: 2,
            //         overflow: TextOverflow.ellipsis,
            //       ),
            //     ),
            //   ),

            if (widget.bannerItems.length > 1)
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.bannerItems.length,
                        (index) => GestureDetector(
                      onTap: () => _goToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.white
                              : AppColors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _BannerItemWidget extends StatelessWidget {
  final BannerModel item;

  const _BannerItemWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: item.image,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      )
    );
  }
}
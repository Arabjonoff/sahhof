import 'package:flutter/material.dart';

enum ShimmerDirection { ltr, rtl, ttb, btt }

class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;
  final ShimmerDirection direction;
  final bool enabled;
  final double shimmerWidthFactor; // the gradient width relative to the widget (0.0 - 1.0)
  final Curve curve;

  const CustomShimmer({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.period = const Duration(milliseconds: 1200),
    this.direction = ShimmerDirection.ltr,
    this.enabled = true,
    this.shimmerWidthFactor = 0.2,
    this.curve = Curves.linear,
  })  : assert(shimmerWidthFactor > 0 && shimmerWidthFactor <= 1.0),
        super(key: key);

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );

    _shimmerAnim = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CustomShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      widget.enabled ? _controller.repeat() : _controller.stop();
    }
    if (widget.period != oldWidget.period) {
      _controller.duration = widget.period;
      if (widget.enabled) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Alignment _beginAlignment() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment(-1.0, 0.0);
      case ShimmerDirection.rtl:
        return Alignment(1.0, 0.0);
      case ShimmerDirection.ttb:
        return Alignment(0.0, -1.0);
      case ShimmerDirection.btt:
        return Alignment(0.0, 1.0);
    }
  }

  Alignment _endAlignment() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment(1.0, 0.0);
      case ShimmerDirection.rtl:
        return Alignment(-1.0, 0.0);
      case ShimmerDirection.ttb:
        return Alignment(0.0, 1.0);
      case ShimmerDirection.btt:
        return Alignment(0.0, -1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final double percent = (_shimmerAnim.value * 2.0) - 1.0;
        final double widthFactor = widget.shimmerWidthFactor ?? 0.2;
        final double leftStop = (1.0 - widthFactor) * ((percent + 1) / 2);
        final double midStart = leftStop;
        final double midEnd = leftStop + widthFactor;
        final double s0 = (midStart - 0.1).clamp(0.0, 1.0);
        final double s1 = midStart.clamp(0.0, 1.0);
        final double s2 = midEnd.clamp(0.0, 1.0);
        final double s3 = (midEnd + 0.1).clamp(0.0, 1.0);
        final gradient = LinearGradient(
          begin: _beginAlignment(),
          end: _endAlignment(),
          colors: [
            widget.baseColor,
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
            widget.baseColor,
          ],
          stops: [s0, s1, s2, s3, (s3 + 0.0001).clamp(0.0, 1.0)],
          tileMode: TileMode.clamp,
        );

        return ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
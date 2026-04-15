import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main stagger controller — drives logo, title, tagline entrance
  late AnimationController _staggerCtrl;

  // Separate controller for bouncing dots (loops)
  late AnimationController _dotsCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsReveal;

  @override
  void initState() {
    super.initState();

    // ── Stagger controller (runs once for 2400ms) ──────────────────
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 32.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.14, 0.38, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.14, 0.38, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.28, 0.48, curve: Curves.easeOut),
      ),
    );
    _dotsReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.46, 0.58, curve: Curves.easeOut),
      ),
    );

    // ── Dots bounce controller (loops after entrance) ──────────────
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _staggerCtrl.forward();

    // Start bouncing dots loop after they've faded in (~1200ms)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _dotsCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────
              AnimatedBuilder(
                animation: _staggerCtrl,
                builder: (_, child) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                ),
                child: _buildLogoContainer(),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────
              AnimatedBuilder(
                animation: _staggerCtrl,
                builder: (_, child) => Opacity(
                  opacity: _titleOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: child,
                  ),
                ),
                child: const Text(
                  'InvoGen',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Tagline ───────────────────────────────────────────
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Professional Invoices, Simplified',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 64),

              // ── Bouncing dots loader ───────────────────────────────
              FadeTransition(
                opacity: _dotsReveal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0.0),
                    const SizedBox(width: 8),
                    _buildDot(0.18),
                    const SizedBox(width: 8),
                    _buildDot(0.36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        size: 58,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDot(double intervalStart) {
    final bounce = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _dotsCtrl,
        curve: Interval(intervalStart, (intervalStart + 0.64).clamp(0.0, 1.0),
            curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: _dotsCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, bounce.value),
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

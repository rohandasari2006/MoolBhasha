import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _imageScale;
  late final Animation<double> _imageOpacity;

  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    // ---------------------------------------------------------
    // SPLASH ANIMATION
    // ---------------------------------------------------------

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _imageScale = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.75,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _imageOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();

    // ---------------------------------------------------------
    // MOVE TO LANGUAGE SELECTION
    // ---------------------------------------------------------

    _splashTimer = Timer(
      const Duration(seconds: 3),
          () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
            const LanguageSelectionScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _imageOpacity.value,
              child: Transform.scale(
                scale: _imageScale.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Image.asset(
                    'assets/final_splash.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
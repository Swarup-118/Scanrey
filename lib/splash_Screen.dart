import 'dart:math';
import 'package:flutter/material.dart';
import 'permission_screen.dart';

// ── Color palette ──────────────────────────────────────────────
const kBg        = Color(0xFF080C14);
const kAccent    = Color(0xFF4F8EF7);   // soft blue
const kGold      = Color(0xFFFFD166);   // warm gold
const kWhite     = Color(0xFFF5F5F5);
const kDim       = Color(0xFF8899AA);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // 1. Mag glass scan
  late AnimationController _scanCtrl;
  late Animation<Offset>   _scanOffset;
  late Animation<double>   _scanFade;

  // 2. Logo reveal inside glass
  late AnimationController _logoCtrl;
  late Animation<double>   _logoFade;
  late Animation<double>   _logoScale;

  // 3. Glass fade out
  late AnimationController _glassFadeCtrl;
  late Animation<double>   _glassFade;

  // 4. Capture ring
  late AnimationController _ringCtrl;
  late Animation<double>   _ringScale;
  late Animation<double>   _ringFade;

  // 5. Sparkle dots around logo
  late AnimationController _sparkCtrl;
  late Animation<double>   _sparkAnim;

  // 6. Text
  late AnimationController _textCtrl;
  late Animation<double>   _nameFade;
  late Animation<Offset>   _nameSlide;
  late Animation<double>   _tagFade;
  late Animation<Offset>   _tagSlide;

  // 7. Exit
  late AnimationController _exitCtrl;
  late Animation<double>   _exitFade;

  bool _showLogo    = false;
  bool _showRing    = false;
  bool _showSpark   = false;
  bool _showText    = false;

  @override
  void initState() {
    super.initState();

    // 1. Scan
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scanOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-130, -160),
          end:   const Offset(110, -60),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(110, -60),
          end:   const Offset(-60, 80),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-60, 80),
          end:   Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
    ]).animate(_scanCtrl);

    _scanFade = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 84),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
    ]).animate(_scanCtrl);

    // 2. Logo
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    // 3. Glass fade
    _glassFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glassFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _glassFadeCtrl, curve: Curves.easeIn),
    );

    // 4. Capture ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringScale = Tween<double>(begin: 0.7, end: 1.6).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeIn),
    );

    // 5. Sparkle dots
    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sparkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sparkCtrl, curve: Curves.easeOut),
    );

    // 6. Text
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _nameFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ));
    _tagFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // 7. Exit
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Mag glass scans
    await Future.delayed(const Duration(milliseconds: 400));
    _scanCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // Logo appears inside glass
    setState(() => _showLogo = true);
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Glass fades away
    _glassFadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Capture ring + sparkles
    setState(() { _showRing = true; _showSpark = true; });
    _ringCtrl.forward();
    _sparkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Text slides in
    setState(() => _showText = true);
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));

    // Smooth exit
    await _exitCtrl.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PermissionScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _logoCtrl.dispose();
    _glassFadeCtrl.dispose();
    _ringCtrl.dispose();
    _sparkCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _scanCtrl, _logoCtrl, _glassFadeCtrl,
          _ringCtrl, _sparkCtrl, _textCtrl, _exitCtrl,
        ]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitFade,
            child: Stack(
              children: [

                // ── Subtle background grid ──────────────────
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter()),
                ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Logo zone ─────────────────────────
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [

                            // Capture ring
                            if (_showRing)
                              Transform.scale(
                                scale: _ringScale.value,
                                child: Opacity(
                                  opacity: _ringFade.value,
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kGold,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Sparkle dots
                            if (_showSpark)
                              ...List.generate(6, (i) {
                                final angle = (i / 6) * 2 * pi - pi / 2;
                                final dist  = 75.0 * _sparkAnim.value;
                                final size  = i % 2 == 0 ? 6.0 : 4.0;
                                return Positioned(
                                  left: 110 + cos(angle) * dist - size / 2,
                                  top:  110 + sin(angle) * dist - size / 2,
                                  child: Opacity(
                                    opacity: (1 - _sparkAnim.value * 0.9)
                                        .clamp(0, 1),
                                    child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        color: i % 2 == 0 ? kGold : kAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),

                            // Logo box
                            if (_showLogo)
                              ScaleTransition(
                                scale: _logoScale,
                                child: FadeTransition(
                                  opacity: _logoFade,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF2A5ECC),
                                          Color(0xFF1A3A8F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kAccent.withOpacity(0.35),
                                          blurRadius: 40,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.image_search_rounded,
                                      size: 56,
                                      color: kWhite,
                                    ),
                                  ),
                                ),
                              ),

                            // Magnifying glass
                            Transform.translate(
                              offset: _scanOffset.value,
                              child: Opacity(
                                opacity: _scanFade.value *
                                    (1 - _glassFadeCtrl.value),
                                child: const _MagGlass(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── App name ──────────────────────────
                      if (_showText)
                        SlideTransition(
                          position: _nameSlide,
                          child: FadeTransition(
                            opacity: _nameFade,
                            child: const Text(
                              'Scanrey',
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.bold,
                                color: kWhite,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ── Tagline ───────────────────────────
                      if (_showText)
                        SlideTransition(
                          position: _tagSlide,
                          child: FadeTransition(
                            opacity: _tagFade,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 1,
                                  color: kGold.withOpacity(0.6),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Find any photo. Instantly.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kDim,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 24,
                                  height: 1,
                                  color: kGold.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Magnifying glass widget ────────────────────────────────────
class _MagGlass extends StatelessWidget {
  const _MagGlass();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _MagGlassPainter(),
    );
  }
}

class _MagGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.42, size.height * 0.42);
    final radius = size.width * 0.32;

    // Circle outline
    final circlePaint = Paint()
      ..color = kWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawCircle(center, radius, circlePaint);

    // Glass fill — subtle blue tint
    final fillPaint = Paint()
      ..color = kAccent.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // Handle
    final handlePaint = Paint()
      ..color = kWhite
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final handleStart = Offset(
      center.dx + radius * cos(pi / 4),
      center.dy + radius * sin(pi / 4),
    );
    final handleEnd = Offset(
      handleStart.dx + radius * 0.65,
      handleStart.dy + radius * 0.65,
    );
    canvas.drawLine(handleStart, handleEnd, handlePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Subtle background grid ─────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2333)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

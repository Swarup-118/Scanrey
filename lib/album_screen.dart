import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_viewer_screen.dart';
import 'video_player_screen.dart';

const kBg      = Color(0xFF080C14);
const kSurface = Color(0xFF0F1623);
const kAccent  = Color(0xFF4F8EF7);
const kGold    = Color(0xFFFFD166);
const kWhite   = Color(0xFFF5F5F5);
const kDim     = Color(0xFF5A6A7A);
const kBorder  = Color(0xFF1A2535);

class AlbumScreen extends StatefulWidget {
  final AssetPathEntity album;
  const AlbumScreen({super.key, required this.album});
  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen>
    with TickerProviderStateMixin {

  List<AssetEntity> _assets = [];
  bool _loading = true;
  bool _showContent = false;
  int _count = 0;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  late AnimationController _textCtrl;
  late Animation<double> _nameFade;
  late Animation<double> _countFade;
  late Animation<double> _textScale;

  late AnimationController _scatterCtrl;
  late AnimationController _gridCtrl;
  late Animation<double> _gridFade;
  late Animation<Offset> _gridSlide;

  @override
  void initState() {
    super.initState();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeInOutCubic,
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _nameFade = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(_textCtrl);

    _countFade = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    ]).animate(_textCtrl);

    _textScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_textCtrl);

    _scatterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gridFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gridCtrl, curve: Curves.easeOut),
    );
    _gridSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _gridCtrl, curve: Curves.easeOut));

    _loadAndAnimate();
  }

  Future<void> _loadAndAnimate() async {
    final count = await widget.album.assetCountAsync;
    final assets = await widget.album.getAssetListPaged(
      page: 0,
      size: 300,
    );
    setState(() {
      _count = count;
      _assets = assets;
      _loading = false;
    });

    _flipCtrl.forward();
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    _scatterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() => _showContent = true);
    _gridCtrl.forward();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _textCtrl.dispose();
    _scatterCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [

          // Grid background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: kWhite,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: kGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'SCANREY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kAccent,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.album.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: kWhite,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ·  $_count items',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: kDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Photo grid ────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: kAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : _showContent
                          ? AnimatedBuilder(
                              animation: _gridCtrl,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _gridFade,
                                  child: SlideTransition(
                                    position: _gridSlide,
                                    child: child,
                                  ),
                                );
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 3,
                                  crossAxisSpacing: 3,
                                ),
                                itemCount: _assets.length,
                                itemBuilder: (context, i) {
                                  final isVideo =
                                      _assets[i].type == AssetType.video;
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => isVideo
                                            ? VideoPlayerScreen(
                                                asset: _assets[i])
                                            : PhotoViewerScreen(
                                                asset: _assets[i]),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image(
                                            image:
                                                AssetEntityImageProvider(
                                              _assets[i],
                                              isOriginal: false,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          if (isVideo)
                                            Container(
                                              color: Colors.black26,
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .play_circle_rounded,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Flip animation overlay ────────────────────
          if (!_showContent && !_loading)
            Positioned.fill(
              child: Container(
                color: kBg,
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_flipCtrl, _textCtrl, _scatterCtrl]),
                    builder: (context, _) {
                      final angle = _flipAnim.value * pi * 2;
                      final scale = 1.0 +
                          sin(_flipAnim.value * pi) * 0.15 +
                          _scatterCtrl.value * 0.3;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle)
                          ..scale(scale),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: _nameFade.value,
                                  child: Text(
                                    widget.album.name,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: kWhite,
                                      letterSpacing: -1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Opacity(
                                  opacity: _countFade.value,
                                  child: Transform.scale(
                                    scale: _textScale.value,
                                    child: Text(
                                      '$_count',
                                      style: const TextStyle(
                                        fontSize: 80,
                                        fontWeight: FontWeight.bold,
                                        color: kAccent,
                                        letterSpacing: -4,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: _countFade.value,
                              child: const Text(
                                'photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: kDim,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Opacity(
                              opacity: _countFade.value *
                                  (1 - _scatterCtrl.value),
                              child: Container(
                                width: 40,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: kGold,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F1825)
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
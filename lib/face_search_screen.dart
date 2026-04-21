import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_viewer_screen.dart';

const kBg      = Color(0xFF080C14);
const kSurface = Color(0xFF0F1623);
const kAccent  = Color(0xFF4F8EF7);
const kGold    = Color(0xFFFFD166);
const kWhite   = Color(0xFFF5F5F5);
const kDim     = Color(0xFF5A6A7A);
const kBorder  = Color(0xFF1A2535);

// ── Albums to skip (unlikely to have faces) ───────────────────
const _skipAlbums = [
  'screenshots', 'screenshot',
  'whatsapp status', 'statuses',
  'whatsapp documents', 'documents',
  'telegram', 'telegram documents',
  'downloads', 'download',
  'whatsapp animated gifs',
  'whatsapp voice notes',
];

enum FaceSearchMode { onlyThis, anywhereInPhoto }

class FaceSearchScreen extends StatefulWidget {
  const FaceSearchScreen({super.key});
  @override
  State<FaceSearchScreen> createState() => _FaceSearchScreenState();
}

class _FaceSearchScreenState extends State<FaceSearchScreen> {
  File? _referenceImage;
  FaceSearchMode? _selectedMode;
  List<AssetEntity> _results = [];
  bool _scanning = false;
  bool _scanned = false;
  String _status = '';
  int _scannedCount = 0;
  int _totalCount = 0;
  int _skippedCount = 0;
  int _facesFound = 0;

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast, // fast mode for speed
    ),
  );

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  Future<void> _pickReferenceImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final inputImage = InputImage.fromFile(file);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      _showSnack('No face detected. Try a clearer front-facing photo.');
      return;
    }

    setState(() {
      _referenceImage = file;
      _results = [];
      _scanned = false;
      _selectedMode = null;
      _scannedCount = 0;
      _skippedCount = 0;
      _facesFound = 0;
    });

    _showModeSheet();
  }

  void _showModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What are you\nlooking for?',
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold,
                color: kWhite, letterSpacing: -1, height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how Scanrey should search your gallery.',
              style: TextStyle(fontSize: 13, color: kDim),
            ),
            const SizedBox(height: 28),
            _ModeCard(
              icon: Icons.person_rounded,
              title: 'Only this person',
              subtitle: 'Photos where only this person appears alone.',
              color: kAccent,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedMode = FaceSearchMode.onlyThis);
                _startScan();
              },
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.group_rounded,
              title: 'Every photo with this person',
              subtitle: 'All photos where this person appears, even with others.',
              color: kGold,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedMode = FaceSearchMode.anywhereInPhoto);
                _startScan();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    if (_referenceImage == null) return;

    setState(() {
      _scanning = true;
      _results = [];
      _scannedCount = 0;
      _skippedCount = 0;
      _facesFound = 0;
      _status = 'Detecting reference face...';
    });

    // Get reference face
    final refInput = InputImage.fromFile(_referenceImage!);
    final refFaces = await _detector.processImage(refInput);

    if (refFaces.isEmpty) {
      _showSnack('Could not detect face. Try a clearer photo.');
      setState(() => _scanning = false);
      return;
    }

    final refFace = refFaces.first;

    // Get all albums
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // Filter out skip albums + count total
    final validAlbums = albums.where((a) =>
      !_skipAlbums.contains(a.name.toLowerCase())
    ).toList();

    int total = 0;
    for (final a in validAlbums) total += await a.assetCountAsync;

    setState(() {
      _totalCount = total;
      _status = 'Scanning gallery...';
    });

    final List<AssetEntity> matched = [];

    for (final album in validAlbums) {
      if (!mounted) return;

      // Load in pages of 100
      int page = 0;
      while (true) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: 100,
        );
        if (assets.isEmpty) break;

        for (final asset in assets) {
          if (!mounted) return;

          // ── Trick 1: Skip tiny files ──────────────────
          // Small files are unlikely to have faces
          if (asset.width != null && asset.height != null) {
            if (asset.width! < 100 || asset.height! < 100) {
              _skippedCount++;
              _scannedCount++;
              continue;
            }
          }

          try {
            // ── Trick 3: Use thumbnail not full file ──────
            final thumb = await asset.thumbnailDataWithSize(
              const ThumbnailSize(300, 300),
            );
            if (thumb == null) {
              _scannedCount++;
              _skippedCount++;
              continue;
            }

            // Write thumb to temp file for ML Kit
            final tempDir = Directory.systemTemp;
            final tempFile = File(
              '${tempDir.path}/scanrey_thumb_${asset.id.hashCode}.jpg'
            );
            await tempFile.writeAsBytes(thumb);

            final input = InputImage.fromFile(tempFile);
            final faces = await _detector.processImage(input);

            // Clean up temp file
            tempFile.deleteSync();

            if (faces.isEmpty) {
              _scannedCount++;
              _skippedCount++;
              continue;
            }

            bool match = false;

            if (_selectedMode == FaceSearchMode.onlyThis) {
              if (faces.length == 1) {
                match = _isSameFace(refFace, faces.first);
              }
            } else {
              for (final face in faces) {
                if (_isSameFace(refFace, face)) {
                  match = true;
                  break;
                }
              }
            }

            if (match) {
              matched.add(asset);
              _facesFound++;

              // ── Trick 4: Progressive results ─────────────
              setState(() => _results = List.from(matched));
            }
          } catch (_) {}

          _scannedCount++;

          // Update UI every 10 photos
          if (_scannedCount % 10 == 0) {
            setState(() {
              _status = 'Scanning... $_scannedCount / $_totalCount';
            });
          }
        }

        page++;
      }
    }

    setState(() {
      _results = matched;
      _scanning = false;
      _scanned = true;
      _status = '';
    });
  }

  bool _isSameFace(Face ref, Face candidate) {
    final refLeft  = ref.landmarks[FaceLandmarkType.leftEye];
    final refRight = ref.landmarks[FaceLandmarkType.rightEye];
    final canLeft  = candidate.landmarks[FaceLandmarkType.leftEye];
    final canRight = candidate.landmarks[FaceLandmarkType.rightEye];

    if (refLeft == null || refRight == null ||
        canLeft == null || canRight == null) {
      return _compareAngles(ref, candidate);
    }

    final refDist = (refRight.position.x - refLeft.position.x).abs();
    final canDist = (canRight.position.x - canLeft.position.x).abs();
    if (refDist == 0 || canDist == 0) return false;

    final refNose = ref.landmarks[FaceLandmarkType.noseBase];
    final canNose = candidate.landmarks[FaceLandmarkType.noseBase];

    if (refNose == null || canNose == null) {
      return _compareAngles(ref, candidate);
    }

    final refNoseRatio =
        (refNose.position.x - refLeft.position.x) / refDist;
    final canNoseRatio =
        (canNose.position.x - canLeft.position.x) / canDist;
    final noseDiff = (refNoseRatio - canNoseRatio).abs();

    final refMouth = ref.landmarks[FaceLandmarkType.bottomMouth];
    final canMouth = candidate.landmarks[FaceLandmarkType.bottomMouth];

    double mouthDiff = 0;
    if (refMouth != null && canMouth != null) {
      final refMouthRatio =
          (refMouth.position.y - refLeft.position.y) / refDist;
      final canMouthRatio =
          (canMouth.position.y - canLeft.position.y) / canDist;
      mouthDiff = (refMouthRatio - canMouthRatio).abs();
    }

    double smileDiff = 0;
    if (ref.smilingProbability != null &&
        candidate.smilingProbability != null) {
      smileDiff =
          (ref.smilingProbability! - candidate.smilingProbability!).abs();
    }

    final score = noseDiff * 0.5 + mouthDiff * 0.3 + smileDiff * 0.2;
    return score < 0.18;
  }

  bool _compareAngles(Face ref, Face candidate) {
    final yawDiff = ((ref.headEulerAngleY ?? 0) -
        (candidate.headEulerAngleY ?? 0)).abs();
    return yawDiff < 15;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '~$seconds sec left';
    return '~${(seconds / 60).ceil()} min left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: kGold, shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('SCANREY',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: kAccent, letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Face',
                              style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold,
                                color: kWhite, letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: '  ·  Search',
                              style: TextStyle(fontSize: 14, color: kDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Upload box ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _scanning ? null : _pickReferenceImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _referenceImage != null
                              ? kAccent.withOpacity(0.5)
                              : kBorder,
                        ),
                      ),
                      child: _referenceImage == null
                          ? Column(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: kAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: kAccent, size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('Upload a face photo',
                                  style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold,
                                    color: kWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to pick a clear front-facing photo',
                                  style: TextStyle(
                                    fontSize: 12, color: kDim,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _referenceImage!,
                                    width: 72, height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Reference face set',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: kWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedMode == null
                                            ? 'Select search mode'
                                            : _selectedMode ==
                                                    FaceSearchMode.onlyThis
                                                ? 'Mode: Only this person'
                                                : 'Mode: Anywhere in photo',
                                        style: const TextStyle(
                                          fontSize: 12, color: kDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_scanning)
                                  GestureDetector(
                                    onTap: _pickReferenceImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kBorder,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        color: kDim, size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scan progress ────────────────────────
                if (_scanning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status row
                          Row(
                            children: [
                              SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  color: kAccent, strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_status,
                                  style: const TextStyle(
                                    fontSize: 13, color: kWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _totalCount > 0
                                  ? _scannedCount / _totalCount
                                  : 0,
                              backgroundColor: kBorder,
                              color: kAccent,
                              minHeight: 6,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Stats row
                          Row(
                            children: [
                              _StatBadge(
                                label: 'Scanned',
                                value: '$_scannedCount',
                                color: kAccent,
                              ),
                              const SizedBox(width: 8),
                              _StatBadge(
                                label: 'Skipped',
                                value: '$_skippedCount',
                                color: kDim,
                              ),
                              const SizedBox(width: 8),
                              _StatBadge(
                                label: 'Matches',
                                value: '${_results.length}',
                                color: kGold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Results header ───────────────────────
                if (_results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 3, height: 14,
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_results.length} match${_results.length == 1 ? '' : 'es'} found',
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: kDim, letterSpacing: 1,
                          ),
                        ),
                        if (_scanning) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kGold.withOpacity(0.3)),
                            ),
                            child: const Text('live',
                              style: TextStyle(
                                fontSize: 10, color: kGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // ── Results grid / empty states ──────────
                Expanded(
                  child: !_scanned && !_scanning && _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.face_retouching_natural_rounded,
                                size: 56, color: kBorder,
                              ),
                              const SizedBox(height: 16),
                              const Text('Upload a face to begin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kDim,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scanrey will scan your entire gallery',
                                style: TextStyle(
                                    fontSize: 13, color: kBorder),
                              ),
                            ],
                          ),
                        )
                      : _scanned && _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                    size: 56, color: kBorder),
                                  const SizedBox(height: 16),
                                  const Text('No matches found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kDim,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try a clearer or different photo',
                                    style: TextStyle(
                                        fontSize: 13, color: kBorder),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  12, 0, 12, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 3,
                                crossAxisSpacing: 3,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (context, i) =>
                                  GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoViewerScreen(
                                        asset: _results[i]),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image(
                                    image: AssetEntityImageProvider(
                                      _results[i],
                                      isOriginal: false,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat badge ────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color,
            ),
          ),
          Text(label,
            style: const TextStyle(fontSize: 9, color: kDim),
          ),
        ],
      ),
    );
  }
}

// ── Mode card ─────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: kWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: kDim),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────
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
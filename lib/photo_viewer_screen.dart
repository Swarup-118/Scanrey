import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

const kBg     = Color(0xFF080C14);
const kSurface = Color(0xFF0F1623);
const kBorder  = Color(0xFF1A2535);
const kWhite   = Color(0xFFF5F5F5);

class PhotoViewerScreen extends StatelessWidget {
  final AssetEntity asset;
  const PhotoViewerScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: kWhite,
              size: 16,
            ),
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image(
            image: AssetEntityImageProvider(
              asset,
              isOriginal: true,
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

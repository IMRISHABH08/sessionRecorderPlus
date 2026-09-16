import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

class ScreenshotCapture {
  const ScreenshotCapture({this.quality = 80});

  final int quality;

  Future<int?> captureToFile(GlobalKey boundaryKey, String filePath) async {
    final uiImage = await _captureImage(boundaryKey);
    if (uiImage == null) return null;
    final raw = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    uiImage.dispose();
    if (raw == null) return null;

    final decoded = img.Image.fromBytes(
      width: uiImage.width,
      height: uiImage.height,
      bytes: raw.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    final jpegBytes = img.encodeJpg(decoded, quality: quality);

    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(jpegBytes, flush: true);
    return jpegBytes.length;
  }

  Future<ui.Image?> _captureImage(GlobalKey boundaryKey) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final renderObject = boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      try {
        return await renderObject.toImage(pixelRatio: 1.0);
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 32));
      }
    }
    return null;
  }
}

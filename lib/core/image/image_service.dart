import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

/// Service used to access the image repository to upload and download images
class ImageService {
  final ImageRepository _imageRepository;
  final CacheManager _cacheManager;
  final ImagePicker _picker;
  final bool Function() _isOnline;

  ImageService(
      {required ImageRepository imageRepository,
      required CacheManager cacheManager,
      required ImagePicker picker,
      required bool Function() isOnline})
      : _imageRepository = imageRepository,
        _cacheManager = cacheManager,
        _picker = picker,
        _isOnline = isOnline;

  /// Uploads an image to the image repository
  Future<Result<String>> uploadImage(Uint8List imageBytes) async {
    try {
      return Result.success(await _imageRepository.uploadImage(imageBytes));
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  /// Downloads and caches an image from a URL
  Future<Result<Uint8List>> getImageFromUrl(String url) async {
    if (!_isOnline()) {
      return Result.canceled(
          "Tried to get image when offline", StackTrace.current);
    }
    try {
      final file = await _cacheManager.getSingleFile(url);

      return Result.success(await file.readAsBytes());
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  /// Picks an image from the gallery or camera using a [ImageSource]
  Future<Result<XFile?>> pickImage(ImageSource source) async {
    try {
      return Result.success(await _picker.pickImage(
          source: source, imageQuality: 100, requestFullMetadata: true));
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  /// Checks if the bytes represent a valid image
  Future<bool> isImageValid(Uint8List bytes) async {
    // If the list is empty, it's not a valid image
    if (bytes.isEmpty) {
      return false;
    }

    try {
      // Attempt to instantiate an image codec
      await ui.instantiateImageCodec(bytes);
      // If successful, the bytes are a valid image format
      return true;
    } catch (e) {
      // An error occurred during decoding, so it's not a valid image
      return false;
    }
  }

  /// Preloads SVG assets
  Future<void> preloadSvg(List<String> paths) async {
    for (var path in paths) {
      var loader = SvgAssetLoader(path);
      await svg.cache
          .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }
  }
}

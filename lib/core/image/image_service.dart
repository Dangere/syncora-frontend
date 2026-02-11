import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class ImageService {
  final ImageRepository _imageRepository;
  final CacheManager _cacheManager;

  ImageService(
      {required ImageRepository imageRepository,
      required CacheManager cacheManager})
      : _imageRepository = imageRepository,
        _cacheManager = cacheManager;

  Future<Result<String>> uploadImage(XFile file) async {
    try {
      return Result.success(await _imageRepository.uploadImage(file));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<Uint8List>> getImageFromUrl(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);

      return Result.success(await file.readAsBytes());
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }
}

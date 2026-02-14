import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class ImageService {
  final ImageRepository _imageRepository;
  final CacheManager _cacheManager;
  final ImagePicker _picker;

  ImageService(
      {required ImageRepository imageRepository,
      required CacheManager cacheManager,
      required ImagePicker picker})
      : _imageRepository = imageRepository,
        _cacheManager = cacheManager,
        _picker = picker;

  Future<Result<String>> uploadImage(Uint8List imageBytes) async {
    try {
      return Result.success(await _imageRepository.uploadImage(imageBytes));
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

  Future<Result<XFile?>> pickImage(ImageSource source) async {
    try {
      return Result.success(await _picker.pickImage(
          source: source, imageQuality: 100, requestFullMetadata: true));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<bool> isImageValid(Uint8List bytes) async {
    // If the list is empty, it's not a valid image
    if (bytes.isEmpty) {
      return false;
    }

    try {
      // Attempt to instantiate an image codec
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      // If successful, the bytes are a valid image format
      return true;
    } catch (e) {
      // An error occurred during decoding, so it's not a valid image
      return false;
    }
  }
}

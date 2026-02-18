import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/image/cloudinary_image_repository.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/image/image_service.dart';

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(
      imageRepository: ref.read(imageRepositoryProvider),
      cacheManager: ref.read(cacheManagerProvider),
      picker: ref.read(imagePickerProvider));
});

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return CloudinaryImageRepository(ref.read(dioProvider));
});

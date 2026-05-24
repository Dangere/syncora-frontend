import 'dart:typed_data';

/// Interface for the image repository
abstract class ImageRepository {
  Future<String> uploadImage(Uint8List imageBytes);
}

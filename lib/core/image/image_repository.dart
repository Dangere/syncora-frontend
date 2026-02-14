import 'dart:typed_data';

abstract class ImageRepository {
  Future<String> uploadImage(Uint8List imageBytes);
}

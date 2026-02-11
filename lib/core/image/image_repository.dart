import 'package:image_picker/image_picker.dart';

abstract class ImageRepository {
  Future<String> uploadImage(XFile image);
}

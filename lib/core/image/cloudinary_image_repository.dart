import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/image/upload_signature_dto.dart';

class CloudinaryImageRepository implements ImageRepository {
  // ignore: non_constant_identifier_names
  final String CLOUDINARY_API_KEY = "358762152499182";

  final Dio _dio;
  CloudinaryImageRepository(this._dio);

  @override
  Future<String> uploadImage(XFile image) async {
    // Getting the signature for the upload
    final signatureResponse = await _dio
        .get("${Constants.BASE_API_URL}/users/images/generate-signature")
        .timeout(const Duration(seconds: 10));

    CloudinarySignatureDTO signature =
        CloudinarySignatureDTO.fromJson(signatureResponse.data);

    var map = signature.toJson();

    map.addAll({
      'api_key': CLOUDINARY_API_KEY,
      'file': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final formData = FormData.fromMap(map);

    final uploadResponse = await _dio
        .post("https://api.cloudinary.com/v1_1/dpo5aj891/image/upload",
            data: formData)
        .timeout(const Duration(seconds: 120));

    return uploadResponse.data['url'] as String;
  }
}

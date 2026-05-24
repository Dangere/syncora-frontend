// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/image/image_repository.dart';
import 'package:syncora_frontend/core/image/upload_signature_dto.dart';

class CloudinaryImageRepository implements ImageRepository {
  /// Cloudinary API key
  final String CLOUDINARY_API_KEY = "358762152499182";

  /// Cloudinary signed upload url
  final String CLOUDINARY_UPLOAD_URL =
      "https://api.cloudinary.com/v1_1/dpo5aj891/image/upload";
  final Dio _dio;
  CloudinaryImageRepository(this._dio);

  /// Uploads an image to cloudinary using a signed upload url
  @override
  Future<String> uploadImage(Uint8List imageBytes) async {
    // Getting the signature for the upload
    final signatureResponse = await _dio
        .get("${Constants.BASE_API_URL}/users/images/generate-signature")
        .timeout(const Duration(seconds: 10));

    CloudinarySignatureDTO signature =
        CloudinarySignatureDTO.fromJson(signatureResponse.data);

    // Creating the form data for the signed upload
    var map = signature.toJson();

    map.addAll({
      'api_key': CLOUDINARY_API_KEY,
      'file': MultipartFile.fromBytes(imageBytes, filename: 'image'),
    });

    // Data created from the signature needs to match exactly the data configured in the cloudinary dashboard
    final formData = FormData.fromMap(map);

    final uploadResponse = await Dio()
        .post(CLOUDINARY_UPLOAD_URL, data: formData)
        .timeout(const Duration(seconds: 240));

    return uploadResponse.data['secure_url'] as String;
  }
}

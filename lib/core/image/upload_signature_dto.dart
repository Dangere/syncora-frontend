class CloudinarySignatureDTO {
  final String signature;
  final String context;
  final String assetFolder;
  final String uploadPreset;
  final int timestamp;

  CloudinarySignatureDTO({
    required this.signature,
    required this.context,
    required this.assetFolder,
    required this.uploadPreset,
    required this.timestamp,
  });

  factory CloudinarySignatureDTO.fromJson(Map<String, dynamic> json) =>
      CloudinarySignatureDTO(
          signature: json['signature'],
          context: json['parameters']['context'],
          assetFolder: json['parameters']['asset_folder'],
          uploadPreset: json['parameters']['upload_preset'],
          timestamp: int.parse(json['parameters']['timestamp']));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'signature': signature,
        'context': context,
        'asset_folder': assetFolder,
        'upload_preset': uploadPreset,
        'timestamp': timestamp
      };

  @override
  String toString() {
    return 'UploadSignatureDTO(signature: $signature, context: $context, folder: $assetFolder, uploadPreset: $uploadPreset, timestamp: $timestamp)';
  }
}

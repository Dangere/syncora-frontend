import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/image/image_provider.dart';

class CropImagePage extends ConsumerStatefulWidget {
  const CropImagePage({super.key, required this.imageFile});

  final XFile imageFile;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CropImagePageState();
}

class _CropImagePageState extends ConsumerState<CropImagePage> {
  final CropController controller = CropController(
    aspectRatio: 1,
    // defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  void _crop() async {
    ui.Image bitmap = await controller.croppedBitmap();

    if (context.mounted) {
      final byteData = await bitmap.toByteData(
        format: ui.ImageByteFormat.png,
      );

      context.pop(byteData!.buffer.asUint8List());
    }
  }

  Future<Uint8List> loadImage() async {
    Uint8List bytes = await widget.imageFile.readAsBytes();

    if (!(await ref.read(imageServiceProvider).isImageValid(bytes))) {
      if (context.mounted) {
        context.pop();
      }
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard_effect.png"),
          ),
          //BACKGROUND GRAPHIC
          Positioned.fill(
            child: Image.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard.png"),
          ),

          FutureBuilder(
              future: loadImage(),
              builder: (context, snapshot) {
                return OverlayLoader(
                  isLoading: !snapshot.hasData,
                  body: Padding(
                    padding: AppSpacing.paddingHorizontalLg +
                        AppSpacing.paddingVerticalXl +
                        const EdgeInsets.only(top: 80),
                    child: !snapshot.hasData
                        ? Center(
                            child: const Icon(Icons.crop_free_sharp),
                          )
                        : AbsorbPointer(
                            absorbing: !snapshot.hasData,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    // color: Colors.red,
                                    child: CropImage(
                                      controller: controller,
                                      image: Image.memory(snapshot.data!),
                                    ),
                                  ),
                                ),
                                // Spacer(
                                //   flex: 2,
                                // ),

                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        AppButton(
                                            width: 50,
                                            size: AppButtonSize.small,
                                            style: AppButtonStyle.filled,
                                            intent: AppButtonIntent.secondary,
                                            onPressed: () =>
                                                controller.rotateLeft(),
                                            child: Icon(Icons
                                                .rotate_90_degrees_ccw_rounded)),
                                        AppButton(
                                            width: 100,
                                            size: AppButtonSize.small,
                                            style: AppButtonStyle.filled,
                                            intent: AppButtonIntent.primary,
                                            onPressed: _crop,
                                            child: const Text("Crop")),
                                        AppButton(
                                            width: 50,
                                            size: AppButtonSize.small,
                                            style: AppButtonStyle.filled,
                                            intent: AppButtonIntent.secondary,
                                            onPressed: () =>
                                                controller.rotateRight(),
                                            child: Icon(Icons
                                                .rotate_90_degrees_cw_rounded)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';

class ProfilePopups {
  static Future<ImageSource?> chooseImageSource(BuildContext context) async {
    return await Dialogs.showContentDialog<ImageSource?>(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "Pick Image From",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                size: AppButtonSize.large,
                style: AppButtonStyle.filled,
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Gallery"),
                  ],
                )),
            SizedBox(
              height: 16,
            ),
            AppButton(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                size: AppButtonSize.large,
                style: AppButtonStyle.filled,
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Camera"),
                  ],
                )),
          ],
        ));
  }
}

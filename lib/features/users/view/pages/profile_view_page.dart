import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/image/image_provider.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class ProfileViewPage extends ConsumerStatefulWidget {
  const ProfileViewPage({super.key, required this.userId});

  final int userId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileViewPageState();
}

class _ProfileViewPageState extends ConsumerState<ProfileViewPage> {
  bool isLoading = false;
  Future _changeProfilePicture() async {
    setState(() {
      isLoading = true;
    });
    Result<XFile?> imagePicked =
        await ref.read(imageServiceProvider).pickImage(ImageSource.gallery);

    if (!imagePicked.isSuccess || imagePicked.data == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "No image picked");
      return;
    }

    if (!context.mounted) return;
    Uint8List? croppedImageBytes =
        await context.push<Uint8List>('/crop-image', extra: imagePicked.data!);

    if (croppedImageBytes == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "No image picked");
      return;
    }
    ref.read(loggerProvider).i("Cropped image successfully");

    Result<String> uploadedImageUrl =
        await ref.read(imageServiceProvider).uploadImage(croppedImageBytes);

    ref.read(loggerProvider).i("Uploaded image url: ${uploadedImageUrl.data}");

    if (!uploadedImageUrl.isSuccess) {
      ref.read(appErrorProvider.notifier).state =
          ErrorMapper.map(uploadedImageUrl.error!);
      return;
    }

    Result updateImageResult = await ref
        .read(usersServiceProvider)
        .updateProfilePicture(uploadedImageUrl.data!);

    if (context.mounted) {
      if (!updateImageResult.isSuccess) {
        ref.read(appErrorProvider.notifier).state =
            ErrorMapper.map(updateImageResult.error!);
      } else {
        SnackBarAlerts.showSuccessSnackBar(
            AppLocalizations.of(context).profileViewPage_ProfileChange,
            context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).profileViewPage_Title),
      ),
      body: Padding(
        padding: AppSpacing.paddingHorizontalLg +
            AppSpacing.paddingVerticalXl +
            const EdgeInsets.only(top: 80),
        child: OverlayLoader(
          isLoading: isLoading,
          body: Column(
            children: [
              AppSpacing.verticalSpaceMd,
              Stack(
                children: [
                  ProfilePicture(userId: widget.userId, radius: 60),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: CircleAvatar(
                          radius: 14,
                          child: IconButton(
                            onPressed: _changeProfilePicture,
                            padding: const EdgeInsets.all(0),
                            icon: Icon(
                              size: 18,
                              Icons.edit,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 42,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [AppShadow.shadow0(context)],
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  child: Column(children: [Center(child: Text("data"))]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

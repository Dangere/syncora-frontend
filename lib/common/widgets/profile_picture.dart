import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

// This uses a FutureBuilder to display a profile picture and update it when it changes
class ProfilePicture extends ConsumerWidget {
  const ProfilePicture(
      {super.key,
      required this.userId,
      this.imageUrl,
      this.radius,
      this.onClick});
  final int userId;
  final String? imageUrl;
  final double? radius;
  final VoidCallback? onClick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onClick,
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius != null ? radius! * 2 : null,
          child: AspectRatio(
              aspectRatio: 1,
              child: ref
                  .watch(userProfileImageProvider(
                      (userId: userId, imageUrl: imageUrl)))
                  .when(
                    skipLoadingOnRefresh: true,
                    skipLoadingOnReload: true,
                    skipError: true,
                    data: (data) {
                      if (data != null) {
                        return Image.memory(
                          fit: BoxFit.cover,
                          data,
                        );
                      } else {
                        return CircleAvatar(
                          radius: radius,
                          child: Icon(
                            Icons.person,
                            size: radius,
                          ),
                        );
                      }
                    },
                    error: (error, stackTrace) {
                      ref.read(loggerProvider).e(error, stackTrace: stackTrace);
                      return Icon(
                        Icons.error,
                        size: radius,
                      );
                    },
                    loading: () {
                      return CircleAvatar(
                        radius: radius,
                        child: Icon(
                          Icons.person,
                          size: radius,
                        ),
                      );
                    },
                  )),
        ),
      ),
    );
  }
}

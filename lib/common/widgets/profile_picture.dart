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
            child: FutureBuilder(
              future: ref.watch(
                  userProfileImageProvider((userId: userId, imageUrl: imageUrl))
                      .future),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  ref.read(loggerProvider).e(snapshot.error);

                  return const Icon(
                    Icons.error,
                  );
                }

                if (snapshot.data != null) {
                  return Image.memory(
                    fit: BoxFit.cover,
                    snapshot.data!,
                  );
                } else {
                  return CircleAvatar(
                    radius: radius,
                    child: const Icon(
                      Icons.person,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

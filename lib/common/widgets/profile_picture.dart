import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class ProfilePicture extends ConsumerWidget {
  const ProfilePicture({super.key, required this.userId, required this.radius});
  final int userId;

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: FutureBuilder(
          future: ref.watch(userProfileImage(userId).future),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              ref.read(loggerProvider).e(snapshot.error);

              return const Icon(
                Icons.error,
              );
            }

            if (snapshot.data != null) {
              return SizedBox.square(
                dimension: radius * 2,
                child: Image.memory(
                  fit: BoxFit.cover,
                  snapshot.data!,
                ),
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
    );
  }
}

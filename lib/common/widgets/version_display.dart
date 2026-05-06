import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';

class VersionDisplay extends ConsumerWidget {
  const VersionDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String version = ref.watch(versionProvider);

    return Positioned.fill(
      bottom: 10,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text("Version $version",
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 12)),
      ),
    );
  }
}

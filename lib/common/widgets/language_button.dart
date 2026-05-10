import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
        onPressed: () {
          BreadcrumbService.instance.add(BreadcrumbType.tap, "Toggle Language");
          ref.read(localeProvider.notifier).toggleLocale();
        },
        icon: Row(children: [Text("EN|عربي")]));
  }
}

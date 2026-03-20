import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';

class GroupInfoPage extends ConsumerStatefulWidget {
  const GroupInfoPage({super.key, required this.groupId});
  final int groupId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends ConsumerState<GroupInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).groupPage_TasksTitle),
      ),
      body: Column(
        children: [],
      ),
    );
  }
}

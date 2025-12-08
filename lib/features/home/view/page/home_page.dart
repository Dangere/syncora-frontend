import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/widgets/outbox_icon.dart';
import 'package:syncora_frontend/common/widgets/syncing_icon.dart';
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';
import 'package:syncora_frontend/core/tests.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/view/widgets/groups_list.dart';
import 'package:syncora_frontend/features/home/view/widgets/verify_email_panel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final connection = ref.watch(connectionProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void logout() {
      ref.read(authNotifierProvider.notifier).logout();
    }

    void openGroupsPage() {
      context.push('/groups');
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading:
            IconButton(onPressed: logout, icon: const Icon(Icons.exit_to_app)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SyncingIcon(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: OutboxIcon(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  color: Colors.grey[200]),
              child: Column(
                children: [
                  Text(
                    'Connection status: ${connection.name}',
                  ),
                  Text(
                    'Welcome back ${authState.value!.user!.username}',
                  ),
                ],
              ),
            ),

            if (ref.read(isVerifiedProvider) == false)
              VerifyEmailPanel(
                authState: authState.value!,
                ref: ref,
              ),

            const Expanded(child: GroupsList())
            // ElevatedButton(onPressed: openGroupsPage, child: Text("Groups page"))
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              bool fakeOnline = ref.read(fakeBeingOnlineProvider);
              ref.read(fakeBeingOnlineProvider.notifier).state = !fakeOnline;

              // ref.read(syncBackendNotifierProvider.notifier).test();
              // ref.read(syncBackendNotifierProvider.notifier).toggleSyncing();
            },
            tooltip: 'TEST',
            icon: const Icon(Icons.signal_wifi_connected_no_internet_4_rounded),
          ),
          IconButton(
            onPressed: () async {
              // bool fakeOnline = ref.read(fakeBeingOnlineProvider);
              // ref.read(fakeBeingOnlineProvider.notifier).state = !fakeOnline;

              // ref.read(syncBackendNotifierProvider.notifier).test();
              // ref.read(syncBackendNotifierProvider.notifier).toggleSyncing();
              // Tests.printDb(ref);
              Tests.printDb(await ref.read(localDbProvider).getDatabase());

              Logger().d(ref
                  .read(authNotifierProvider)
                  .value
                  ?.asAuthenticated!
                  .isVerified);
            },
            tooltip: 'TEST',
            icon: const Icon(Icons.text_rotation_angleup_sharp),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

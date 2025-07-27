import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/common/widgets/syncing_icon.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

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
        leading:
            IconButton(onPressed: logout, icon: const Icon(Icons.exit_to_app)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SyncingIcon(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Connection status: ${connection.name}',
            ),
            Text(
              'Welcome back ${authState.value!.user!.username}',
            ),
            ElevatedButton(
                onPressed: openGroupsPage, child: Text("Groups page"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          bool fakeOnline = ref.read(fakeBeingOnlineProvider);
          ref.read(fakeBeingOnlineProvider.notifier).state = !fakeOnline;

          // ref.read(syncBackendNotifierProvider.notifier).test();
        },
        tooltip: 'Sync',
        child: const Icon(Icons.cloud_sync),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

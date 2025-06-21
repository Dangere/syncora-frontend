import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/core/syncing/sync_notifier.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

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
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
          ref.read(backendSyncProvider.notifier).sync();
        },
        tooltip: 'Sync',
        child: const Icon(Icons.cloud_sync),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

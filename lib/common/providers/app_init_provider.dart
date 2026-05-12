import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';

final appInitializeProvider = FutureProvider<void>((ref) async {
  await ref.read(diagnosticsServiceProvider).initialize();

  ref.read(isOnlineProvider);
  ref.read(authProvider);

  ref.read(syncBackendProvider);
  ref.read(googleSignInProvider);

  ref.read(syncBackendProvider);

  // await Future.delayed(Duration(seconds: 10));
});

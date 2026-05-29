import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/error_management/error_mapper.dart';
import 'package:syncora_frontend/core/image/image_providers.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';

/// Provider used to initialize other providers while the splash screen is loading
final appInitializeProvider = FutureProvider<void>((ref) async {
  // Preloading SVGs
  await ref.read(imageServiceProvider).preloadSvg([
    "assets/logos/google-icon.svg",
    "assets/logos/syncora-logo.svg",
  ]);
  await ref.read(diagnosticsServiceProvider).initialize();

  ref.read(isOnlineProvider);
  ref.read(authProvider);

  ref.read(syncBackendProvider);
  ref.read(googleSignInProvider);

  ref.read(syncBackendProvider);

  if (kIsWeb) {
    await ErrorMapper.initializeSourceMap();
  }
  // Delay to avoid builds when transitions are needed
  Future.delayed(const Duration(seconds: 1));
});

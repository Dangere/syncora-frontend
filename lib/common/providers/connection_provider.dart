import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/router.dart';

// ignore: non_constant_identifier_names
final debug_fakeBeingOnlineProvider = StateProvider<bool>((ref) {
  return false;
});

/// Notifier for the connection status specific to web
class WebConnectionCheckerNotifier extends Notifier<ConnectionStatus> {
  final int _disconnectOnFailCount = 2;
  final List<Uri> _connectionCheckUrls = [
    Uri.parse('https://httpbin.org/get'),
    Uri.parse(Constants.BASE_URL)
  ];
  int _reconnectionFailCount = 0;
  final Duration _checkInterval = const Duration(seconds: 6);
  bool running = true;
  @override
  ConnectionStatus build() {
    if (!kIsWeb) {
      return ConnectionStatus.checking;
    }

    Future.microtask(() async {
      while (running) {
        await Future.delayed(_checkInterval);
        if (!running) break;

        for (var i = 0; i < _connectionCheckUrls.length; i++) {
          if (!running) break;

          try {
            final response = await Dio().get(_connectionCheckUrls[i].toString(),
                options: Options(receiveTimeout: const Duration(seconds: 5)));
            if (!running) break;

            // If we get a successful response that is between 200 and 300, we break out of the loop
            if (response.statusCode != null &&
                (response.statusCode! >= 200 && response.statusCode! < 300)) {
              state = ConnectionStatus.connected;
              _reconnectionFailCount = 0;
              break;
            }

            // If its the last URI and the status code is null or not between 200 and 300, we increase the fail count
            if (i == _connectionCheckUrls.length - 1) {
              _reconnectionFailCount++;
              continue;
            }
          } catch (e) {
            // If its the last URI and still throwing, we increase the fail count
            if (i == _connectionCheckUrls.length - 1) {
              _reconnectionFailCount++;
            }
          }
        }
        if (_reconnectionFailCount >= _disconnectOnFailCount) {
          state = ConnectionStatus.disconnected;
        }
      }
    });

    ref.listen(debug_fakeBeingOnlineProvider, (previous, next) {
      if (next) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.disconnected;
      }
      running = false;
    });

    ref.onDispose(() => running = false);

    return ConnectionStatus.checking;
  }
}

/// Notifier for the connection status specific to mobile
class ConnectionNotifier extends Notifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    if (kIsWeb) {
      return ConnectionStatus.checking;
    }
    final connectionChecker = InternetConnectionChecker.createInstance(
      addresses: [
        AddressCheckOption(
          uri: Uri.parse('https://google.com'),
          timeout: const Duration(seconds: 3),
        ),
        AddressCheckOption(
          uri: Uri.parse('https://flutter.dev'),
          timeout: const Duration(seconds: 3),
        ),
      ],
    );

    var sub = connectionChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.disconnected:
            state = ConnectionStatus.disconnected;
            break;
          case InternetConnectionStatus.connected:
            state = ConnectionStatus.connected;
            break;
          case InternetConnectionStatus.slow:
            state = ConnectionStatus.connected;
            break;
        }
      },
    );

    ref.listen(debug_fakeBeingOnlineProvider, (previous, next) {
      if (next) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.disconnected;
      }
      sub.cancel();
    });

    ref.onDispose(() => sub.cancel());

    return ConnectionStatus.checking;
  }
}

final _connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionStatus>(
        ConnectionNotifier.new);

final _webConnectionProvider =
    NotifierProvider<WebConnectionCheckerNotifier, ConnectionStatus>(
        WebConnectionCheckerNotifier.new);

final isOnlineProvider = Provider<bool>((ref) {
  var status = kIsWeb
      ? ref.watch(_webConnectionProvider)
      : ref.watch(_connectionProvider);
  BreadcrumbService.instance.add(BreadcrumbType.connection, status.name);

  ref.listen(_connectionProvider, (previous, next) {
    BuildContext? context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    if (next == ConnectionStatus.connected) {
      SnackBarAlerts.showSuccessSnackBar(
          AppLocalizations.of(context).notification_Online_Connected, context);
    } else {
      SnackBarAlerts.showAlertSnackBar(
          AppLocalizations.of(context).notification_Online_Disconnected,
          context);
    }
  });
  return status == ConnectionStatus.connected;
});

enum ConnectionStatus { checking, connected, disconnected }

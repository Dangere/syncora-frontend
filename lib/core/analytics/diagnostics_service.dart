import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A service used to get the diagnostics and info about the device
class DiagnosticsService {
  final String Function() _languageCode;

  DiagnosticsService({required String Function() languageCode})
      : _languageCode = languageCode;

  final String _platform = kIsWeb ? "Web" : Platform.operatingSystem;
  late String _appVersion;
  late String _osVersion;
  late String _deviceModel;

  /// A unique identifier for the device used in the custom headers sent to backend
  final String _deviceId =
      DateTime.now().toUtc().microsecondsSinceEpoch.toString();

  String get appVersion => _appVersion;
  String get platform => _platform;
  String get locale => _languageCode();
  String get osVersion => _osVersion;
  String get deviceModel => _deviceModel;
  String get deviceId => _deviceId;

  /// Initializes the diagnostics
  Future<void> initialize() async {
    var packageInfo = await PackageInfo.fromPlatform();
    _appVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    await _setOsAndModel();
  }

  /// Sets the os and model
  Future<void> _setOsAndModel() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      _osVersion = webInfo.platform ?? 'unknown';
      _deviceModel = webInfo.browserName.name;
      return;
    }

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _osVersion = androidInfo.version.release;
      _deviceModel = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _osVersion = iosInfo.systemVersion;
      _deviceModel = iosInfo.model;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      _osVersion = linuxInfo.version ?? 'unknown';
      _deviceModel = linuxInfo.name;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macosInfo = await deviceInfo.macOsInfo;
      _osVersion =
          "${macosInfo.majorVersion}.${macosInfo.minorVersion}.${macosInfo.patchVersion}";
      _deviceModel = macosInfo.model;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      _osVersion = windowsInfo.buildNumber.toString();
      _deviceModel = windowsInfo.userName;
    }
  }
}

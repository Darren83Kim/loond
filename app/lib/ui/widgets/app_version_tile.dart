import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../legal/service_disclaimer.dart';

/// Version line from the platform package info (versionName), not a hardcoded string.
class AppVersionTile extends StatefulWidget {
  const AppVersionTile({super.key});

  @override
  State<AppVersionTile> createState() => _AppVersionTileState();
}

class _AppVersionTileState extends State<AppVersionTile> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      if (!mounted || version.isEmpty) return;
      setState(() => _version = version);
    } catch (_) {
      // Plugin missing in widget tests and on unsupported platforms.
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    final subtitle = version == null
        ? '$kAppDisplayName · 민간 비제휴 안내'
        : '$kAppDisplayName $version · 민간 비제휴 안내';
    return ListTile(
      title: const Text('앱 정보'),
      subtitle: Text(subtitle),
    );
  }
}

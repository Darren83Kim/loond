import 'package:flutter/material.dart';

import '../../ads/ads_consent.dart';

/// UMP privacy-options entry. Hidden unless the SDK requires it.
class PrivacyOptionsTile extends StatelessWidget {
  const PrivacyOptionsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdsConsent.instance,
      builder: (context, _) {
        if (!AdsConsent.instance.privacyOptionsRequired) {
          return const SizedBox.shrink();
        }
        return ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('광고 개인정보 옵션'),
          subtitle: const Text('광고 동의 선택을 바꿀 수 있어요'),
          onTap: () => AdsConsent.instance.showPrivacyOptions(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion extends StatelessWidget {
  const AppVersion({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 1,
              horizontal: 8,
            ),
            child: Text('v${data.version}'),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

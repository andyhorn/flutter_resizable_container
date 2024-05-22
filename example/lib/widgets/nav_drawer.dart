import 'package:example/widgets/app_version.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 15),
          Text(
            'Basic Examples',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ListTile(
            title: const Text('Basic Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('basic'),
          ),
          ListTile(
            title: const Text('Ratio Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('ratio'),
          ),
          ListTile(
            title: const Text('Pixels Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('pixels'),
          ),
          ListTile(
            title: const Text('Custom Divider Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('divider'),
          ),
          const SizedBox(height: 15),
          Text(
            'Controller Examples',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ListTile(
            title: const Text('Controller Listen Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('listen'),
          ),
          ListTile(
            title: const Text('Controller Set Sizes Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('sizes'),
          ),
          const Spacer(),
          const AppVersion(),
        ],
      ),
    );
  }
}

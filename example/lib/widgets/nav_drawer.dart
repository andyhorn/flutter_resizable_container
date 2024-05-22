import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 15),
          Text(
            'Examples',
            style: Theme.of(context).textTheme.titleMedium,
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text('Basic Example'),
              onTap: () => Navigator.of(context).pushReplacementNamed('basic'),
            ),
            ListTile(
              title: const Text('Ratio Example'),
              onTap: () => Navigator.of(context).pushReplacementNamed('ratio'),
            ),
          ],
        ),
      ),
    );
  }
}

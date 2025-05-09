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
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close),
              ),
            ),
          ),
          const NavSectionHeader(title: 'Basic Examples'),
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
          ListTile(
            title: const Text('Shrink and Flex Example'),
            onTap: () => Navigator.of(context).pushReplacementNamed('shrink'),
          ),
          ListTile(
            title: const Text('FutureBuilder Shrink Example'),
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('future-builder-shrink'),
          ),
          ListTile(
            title: const Text('Cascading Delta Example'),
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('cascading-delta'),
          ),
          const SizedBox(height: 15),
          const NavSectionHeader(title: 'Controller Examples'),
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

class NavSectionHeader extends StatelessWidget {
  const NavSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

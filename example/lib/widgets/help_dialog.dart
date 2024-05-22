import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final Widget content;

  static void show({
    required BuildContext context,
    required Widget child,
  }) {
    showDialog(
      context: context,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentTextStyle: Theme.of(context).textTheme.bodyLarge,
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class ShrinkAndFlexHelpDialog extends StatelessWidget {
  const ShrinkAndFlexHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const ShrinkAndFlexHelpDialog._(
        key: Key('ShrinkAndFlexHelpDialog'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HelpDialog(
      title: 'About this example',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'In this example, the left child is using a '),
              TextSpan(
                  text: 'ResizableSize.expand()',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  )),
              TextSpan(text: ' while the right child is using a '),
              TextSpan(
                  text: 'ResizableSize.shrink()',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  )),
              TextSpan(text: '.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(
                text:
                    'This means that the left child will take up all available space, while the right child will take up only the space it needs.',
              ),
            ],
          )),
        ],
      ),
    );
  }
}

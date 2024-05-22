import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class PixelsExampleHelpDialog extends StatelessWidget {
  const PixelsExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const PixelsExampleHelpDialog._(
        key: Key('PixelsExampleHelpDialog'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HelpDialog(
      title: 'About this example',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In this example, the first child (left) has been given an absolute size of 333 logical pixels.',
          ),
          SizedBox(height: 15),
          Text(
            'This is different from the other two size options, which both use proportions of the available space.',
          ),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'The second child uses the default'),
              TextSpan(
                text: ' ResizableSize.expand() ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'and has been given the remaining available space.',
              ),
            ],
          )),
        ],
      ),
    );
  }
}

import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class CascadingDeltaHelpDialog extends StatelessWidget {
  const CascadingDeltaHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const CascadingDeltaHelpDialog._(
        key: Key('CascadingDeltaHelpDialog'),
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
            'In this example, there are four children, each with a minimum width of 50 pixels.',
          ),
          SizedBox(height: 12),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Use the '),
            TextSpan(
              text: 'Cascade',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' switch to enable/disable the '),
            TextSpan(
              text: 'cascadeNegativeDelta',
              style: TextStyle(
                fontFamily: 'Monospace',
                color: Colors.blueGrey,
              ),
            ),
            TextSpan(text: ' flag in the ResizableContainer.'),
          ])),
          SizedBox(height: 12),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'With the switch '),
            TextSpan(
              text: 'enabled',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ', reducing the size of a child beyond its bound will "cascade" the change to its sibling(s).',
            ),
            TextSpan(text: ' With the switch '),
            TextSpan(
              text: 'disabled',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ', reducing the size of a child beyond its bound will have no effect (default behavior).',
            ),
          ])),
        ],
      ),
    );
  }
}

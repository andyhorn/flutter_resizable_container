import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class ControllerSetSizesExampleHelpDialog extends StatelessWidget {
  const ControllerSetSizesExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const ControllerSetSizesExampleHelpDialog._(
        key: Key('ControllerSetSizesExampleHelpDialog'),
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
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'This example retains a reference to the '),
              TextSpan(
                text: 'ResizableController',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' for the purpose of using the '),
              TextSpan(
                text: 'setSizes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' method.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(
                text:
                    'Using the menu button in the app bar, you can programmatically set the sizes of each of the children using ',
              ),
              TextSpan(
                text: 'ratios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', '),
              TextSpan(
                text: 'pixels',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', or '),
              TextSpan(
                text: 'expand/flex',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'The '),
              TextSpan(
                text: 'ratios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' setter will assign the children with ratios of ',
              ),
              TextSpan(
                text: '0.5',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', '),
              TextSpan(
                text: '0.2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', and '),
              TextSpan(
                text: '0.3',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'The '),
              TextSpan(
                text: 'pixels',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' setter will use '),
              TextSpan(
                text: 'MediaQuery.sizeOf(context)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    ' to measure the available space, then assign the children with ',
              ),
              TextSpan(
                text: '1/4',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', '),
              TextSpan(
                text: '1/2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', and '),
              TextSpan(
                text: '1/4',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' of the width.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'The '),
              TextSpan(
                text: 'flex',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' setter will assign the children with flex values of ',
              ),
              TextSpan(
                text: '1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', '),
              TextSpan(
                text: '3',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ', and '),
              TextSpan(
                text: '2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '.'),
            ],
          )),
        ],
      ),
    );
  }
}

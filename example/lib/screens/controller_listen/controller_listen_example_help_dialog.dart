import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class ControllerListenExampleHelpDialog extends StatelessWidget {
  const ControllerListenExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const ControllerListenExampleHelpDialog._(
        key: Key('ControllerListenExampleHelpDialog'),
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
              TextSpan(
                text: 'In this example, we have retained a reference to the',
              ),
              TextSpan(
                text: ' ResizableController ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text:
                    'in our StatefulWidget. This allows us to add a listener to the controller and react to any changes in our business logic.',
              ),
            ],
          )),
          SizedBox(height: 15),
          Text(
            'In this example, we have set up a listener that extracts the sizes of the children and updates the label at the bottom of the screen.',
          ),
        ],
      ),
    );
  }
}

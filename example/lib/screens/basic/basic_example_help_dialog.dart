import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class BasicExampleHelpDialog extends StatelessWidget {
  const BasicExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const BasicExampleHelpDialog._(
        key: Key('BasicExampleHelpDialog'),
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
            'In this example, there are two children.',
          ),
          Text.rich(TextSpan(
            children: [
              TextSpan(text: 'Each child uses the default '),
              TextSpan(
                text: 'ResizableSize.expand()',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' attribute.'),
            ],
          )),
          SizedBox(height: 15),
          Text(
            'This results in two areas of equal width that can be adjusted freely.',
          ),
        ],
      ),
    );
  }
}

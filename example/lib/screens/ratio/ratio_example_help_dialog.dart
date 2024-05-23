import 'package:example/widgets/help_dialog.dart';
import 'package:flutter/material.dart';

class RatioExampleHelpDialog extends StatelessWidget {
  const RatioExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    HelpDialog.show(
      context: context,
      child: const RatioExampleHelpDialog._(
        key: Key('RatioExampleHelpDialog'),
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
              TextSpan(
                text: 'In this example, the two outer children are using a',
              ),
              TextSpan(
                text: ' ResizableSize.ratio(0.15), ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: 'while the center child is using a'),
              TextSpan(
                text: ' ResizableSize.expand()',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: '.'),
            ],
          )),
          SizedBox(height: 15),
          Text.rich(TextSpan(
            children: [
              TextSpan(
                text:
                    'This gives the outer children a fixed starting size of 15% of the total available width and then allocates',
              ),
              TextSpan(
                text: ' all ',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text:
                    'of the remaining space, 70% of the total width, to the middle child.',
              ),
            ],
          )),
        ],
      ),
    );
  }
}

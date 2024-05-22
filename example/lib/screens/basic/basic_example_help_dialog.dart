import 'package:flutter/material.dart';

class BasicExampleHelpDialog extends StatelessWidget {
  const BasicExampleHelpDialog._({super.key});

  static void show({
    required BuildContext context,
  }) {
    showDialog(
      context: context,
      builder: (context) => const BasicExampleHelpDialog._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.15,
        vertical: MediaQuery.sizeOf(context).height * 0.15,
      ),
      title: const Text('About this example'),
      contentTextStyle: Theme.of(context).textTheme.bodyLarge,
      content: const Column(
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

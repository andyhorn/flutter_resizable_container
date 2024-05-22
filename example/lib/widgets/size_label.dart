import 'package:flutter/material.dart';

class SizeLabel extends StatelessWidget {
  const SizeLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight.toStringAsFixed(2);
      final width = constraints.maxWidth.toStringAsFixed(2);

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Height: $height', textAlign: TextAlign.center),
            Text('Width: $width', textAlign: TextAlign.center),
          ],
        ),
      );
    });
  }
}

import 'package:example/screens/basic/basic_example_screen.dart';
import 'package:example/screens/controller_listen/controller_listen_example_screen.dart';
import 'package:example/screens/controller_set_sizes/controller_set_sizes_example_screen.dart';
import 'package:example/screens/divider/custom_divider_example_screen.dart';
import 'package:example/screens/pixels/pixels_example_screen.dart';
import 'package:example/screens/ratio/ratio_example_screen.dart';
import 'package:example/screens/shrink_and_flex/shrink_and_flex_example_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      initialRoute: 'basic',
      routes: {
        'basic': (context) => const BasicExampleScreen(),
        'ratio': (context) => const RatioExampleScreen(),
        'pixels': (context) => const PixelsExampleScreen(),
        'listen': (context) => const ControllerListenExampleScreen(),
        'sizes': (context) => const ControllerSetSizesExampleScreen(),
        'divider': (context) => const CustomDividerExampleScreen(),
        'shrink': (context) => const ShrinkAndFlexExampleScreen(),
      },
    );
  }
}

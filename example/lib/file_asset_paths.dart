enum FileAssetPaths {
  basicScreen(
    'lib/screens/basic/basic_example_screen.dart',
  ),
  controllerListenScreen(
    'lib/screens/controller_listen/controller_listen_example_screen.dart',
  ),
  controllerSetSizesScreen(
    'lib/screens/controller_set_sizes/controller_set_sizes_example_screen.dart',
  ),
  dividerScreen(
    'lib/screens/divider/custom_divider_example_screen.dart',
  ),
  pixelsScreen(
    'lib/screens/pixels/pixels_example_screen.dart',
  ),
  ratioScreen(
    'lib/screens/ratio/ratio_example_screen.dart',
  ),
  shrinkAndFlexScreen(
    'lib/screens/shrink_and_flex/shrink_and_flex_example_screen.dart',
  ),
  cascadingDeltaScreen(
    'lib/screens/cascading_delta/cascading_delta_screen.dart',
  ),
  ;

  const FileAssetPaths(this.path);
  final String path;
}

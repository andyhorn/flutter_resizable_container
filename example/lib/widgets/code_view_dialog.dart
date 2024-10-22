import 'package:example/extensions/int_ext.dart';
import 'package:example/file_asset_paths.dart';
import 'package:flutter/material.dart';

class CodeViewDialog extends StatelessWidget {
  const CodeViewDialog._({
    super.key,
    required this.filePath,
  });

  static void show({
    required BuildContext context,
    required FileAssetPaths filePath,
  }) {
    showDialog(
      context: context,
      builder: (context) => CodeViewDialog._(
        key: const Key('CodeViewDialog'),
        filePath: filePath.path,
      ),
    );
  }

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  filePath,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(
            height: 0,
          ),
          Expanded(
            child: FutureBuilder(
              future: DefaultAssetBundle.of(context).loadString(filePath),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error!.toString()));
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final content = snapshot.data!;
                final lines = content.split('\n');
                final maxDigits = lines.length.digitCount;

                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SelectionArea(
                    focusNode: FocusNode(),
                    selectionControls: DesktopTextSelectionControls(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final digitCount = (index + 1).digitCount;
                          final padding = (maxDigits - digitCount) + 2;
                          final label = '${index + 1}${' ' * padding}';

                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: label),
                                TextSpan(text: lines[index]),
                              ],
                            ),
                            style: const TextStyle(
                              fontFamily: 'Reddit Mono',
                            ),
                            softWrap: true,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

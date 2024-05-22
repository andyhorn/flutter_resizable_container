import 'package:flutter/material.dart';

class CodeViewDialog extends StatelessWidget {
  const CodeViewDialog._({
    super.key,
    required this.filePath,
  });

  static void show({
    required BuildContext context,
    required String filePath,
  }) {
    showDialog(
      context: context,
      builder: (context) => CodeViewDialog._(
        key: const Key('CodeViewDialog'),
        filePath: filePath,
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
                final characters = lines.length % 10 + 1;

                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SelectionArea(
                    focusNode: FocusNode(),
                    selectionControls: DesktopTextSelectionControls(),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final length = (index + 1).toString().length;
                          final padding = (characters - length) * 2 + 2;
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

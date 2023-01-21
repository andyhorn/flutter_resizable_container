**ResizableContainer**s add flexibility and personalization to your UI.

Each container is configured to lay out its children along either the horizontal or vertical axis. These children can then be resized within their shared space using a click-and-drag control.

## Features

Build a UI with one or as many `ResizableContainer`s as you want, even nesting them for fully customizable interfaces.

Each child can be given unbounded flexibility (within the available space) _or_ constrained with a _maximum_ and/or _minimum_ size (in logical pixels).

## Getting started

Add this package to your `pubspec.yaml` or install using the command line.

```dart
flutter pub add flutter_resizable_container
```

## Usage

First, add a `ResizableContainer` to your widget tree and give it a `direction` of type `Axis`: this is the direction in which the child objects will be laid out and the direction in which the children's size will be allowed to flex.

Second, add a list of `ResizableChildData` objects containing configuration data for each child element:

  * `child: Widget` - the widget to be displayed in the UI and resized by the user
  * `startingRatio: double` - this ratio will be used to determine the child's initial size upon the first render, based on the available space of the parent `ResizableContainer`. 
    
    **Note**: this value is required for each child and the sum of all of a container's child ratios must equal `1.0`

  * `minSize: double?` (optional) - this value indicates the absolute minimum size (in logical pixels) this child can take; any adjustments that would reduce the child's size _below_ this value will be ignored
  * `maxSize: double?` (optional) - similar to the [minSize], this indicates the absolute maximum size (in logical pixels) this child can take; any adjustments that would increase the child's size _above_ this value will be ignored

### Example

```dart
@override
Widget build(BuildContext context) {
  return ResizableContainer(
    direction: Axis.horizontal,
    children: [
      ResizableChildData(
        startingRatio: 0.75,
        minSize: 150,
        child: const Center(
          child: Text('Left 3/4'),
        ),
      ),
      ResizableChildData(
        startingRatio: 0.25,
        maxSize: 500,
        child: const Center(
          child: ResizableContainer(
            direction: Axis.vertical,
            children: [
              ResizableChildData(
                startingRatio: 0.5,
                child: const Center(
                  child: Text('Upper right'),
                ),
              ),
              ResizableChildData(
                startingRatio: 0.5,
                child: const Center(
                  child: Text('Lower right'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

This would give you a two-pane (horizontal layout) container with a divider and grab handle 3/4 of the way across the screen from the left-hand side.

Using this handle, the user could then shrink the left-hand pane down to its minimum size of 150px _or_ until the right-hand pane expands to its maximum size of 500px, whichever comes first. 

They can also adjust the height of the two vertically-stacked children on the right side. These right-side children are given unbounded flexibility, which means each one can take the full space (with the other being given 0px height and no longer appearing on the screen).

## License

Copyright 2023 Andrew Horn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

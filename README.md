**ResizableContainer**s add flexibility and personalization to your UI.

## Features

* Nest as many `ResizableContainer`s as you want
* Configure each child's initial size, minimum size, and/or maximum size
* Customize the width and color of the divider(s) between children
* Programmatically change the ratios of the children at any time

## Getting started

Add this package to your `pubspec.yaml` or install using the command line.

```dart
flutter pub add flutter_resizable_container
```

## Usage

First, add a `ResizableContainer` to your widget tree and give it a `direction` of type `Axis`: this is the direction in which the child objects will be laid out and the direction in which the children's size will be allowed to flex.

You can also provide a `dividerWidth` and/or `dividerColor` to customize the appearance of the dividers between children.

```dart
ResizableContainer(
  direction: Axis.horizontal,
  dividerWidth: 5,
  dividerColor: Colors.blue,
  children: [
    // ...
  ],
)
```

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
    dividerWidth: 3.0,
    dividerColor: Colors.blue,
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
            dividerColor: Colors.green,
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

![ResizableContainer example](doc/screenshot.png)

In the example, there is a two-pane (horizontal layout) container with a divider and grab-handle 3/4 of the way across the screen from the left-hand side.

Using this handle, a user could shrink the left-hand pane down to its minimum size of 150px _or_ until the right-hand pane expands to its maximum size of 500px, whichever comes first. 

They can also adjust the height of the two vertically-stacked children on the right side. These right-side children are given unbounded flexibility, which means each one can take the full space (with the other being given 0px height and no longer appearing on the screen).

### Using a controller

When creating a `ResizableChildData`, you provide a `startingRatio` to give it a size relative to the available space. After the frame builds, the user may freely resize it and any other child. To set the ratio programmatically, use a `ResizableController`: 

```dart
final controller = ResizableController();

// ...

child: ResizableContainer(
  controller: controller,
  child: // ...
```

Then, using `controller.setRatios`, you can set the ratios for all the children at once. This function has the same limitation as `startingRatio` in that all the ratios must add to one, and there must be one ratio per child. 

```dart
void printControllerInfo() {
  print("Details about the controller: ");
  print("  Ratios: ${controller.ratios}");
  print("  Absolute Sizes: ${controller.sizes}");
  print("  Available space: ${controller.availableSpace}");
  print("  Number of children: ${controller.numChildren}");
}

void resetRatios() {
  // Assuming this controller only has two children
  controller.setRatios([0.5, 0.5]);
}
```

Be sure to dispose the controller when you're done with it:

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## License

Copyright 2023 Andrew Horn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

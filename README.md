# Flutter Resizable Container

Add flexibility and interaction to your UI with ease.

View the interactive example app at [andyhorn.github.io/flutter_resizable_container](https://andyhorn.github.io/flutter_resizable_container)

![Flutter Resizable Container](./doc/screenshot.png)

## Features

* `ResizableContainer`s are fully nestable
* Customize the size/thickness, indentation, and color of the dividers between children
* Respond to user interactions with `onHoverEnter` and `onHoverExit` callbacks on dividers
* Programmatically set the ratios of the children

## Getting started

Add this package to your `pubspec.yaml` or install using the command line.

```dart
flutter pub add flutter_resizable_container
```

## Usage

### Direction and Children

Add a `ResizableContainer` to your widget tree and give it a `direction` of type `Axis` - this is the direction in which the `children` will be laid out and the direction in which their size will be allowed to flex.

```dart
ResizableContainer(
  direction: Axis.horizontal,
  children: [
    MyCoolWidget(),
    MyOtherCoolWidget(),
  ],
)
```

In the example above, the two children will take up the maximum available height while being allowed to flex their width.

### ResizableController

#### Setup

Second, add a `ResizableController`. This controller is used to respond to resize events and calculate the size of each child widget. When creating a controller, you must provide a list of `ResizableChildData` objects. These configuration objects control the `startingRatio`, `minSize`, and `maxSize` of their corresponding `Widget` (based on their respective indices).

For example:

```dart
ResizableContainer(
    controller: ResizableController(
        data: const [
            ResizableChildData(
                minSize: 100,
            ),
            ResizableChildData(
                maxSize: 500,
            ),
            ResizableChildData(
                startingRatio: 0.25,
            ),
        ],
    ),
),
```

In the first configuration objects, a `minSize` of `100` was supplied - this means that the corresponding child `Widget` will not be allowed to shrink below 100 logical pixels.

In the second object, a `maxSize` of `500` was supplied - this means that the corresponding child `Widget` will not be allowed to grow beyond 500 logical pixels.

In the first object, a `startingRatio` of `0.5` was supplied. When the container is initially laid out, the corresponding child `Widget` will be sized to 1/2 of the available space. Since the other two configuration objects were not supplied with a `startingRatio`, the remaining available space will be evenly distributed between them.

#### Using a ResizableController

If you retain a reference to the `ResizableController`, you can listen to its changes as well as programmatically set/reset the `ratios` of the container's children.

```dart
final controller = ResizableController(
    data: const [
        ResizableChildData(),
        ResizableChildData(),
        ResizableChildData(),
    ],
);

@override
void initState() {
    super.initState();

    controller.addListener(() {
        // ... react to size change events
    });
}

@override
void dispose() {
    controller.dispose(); // don't forget to dispose your controller
    super.dispose();
}

// (somewhere else in your code)
// use the ratios setter to programmatically set the ratios of the 
// container's children.
onTap: () => controller.ratios = [0.25, 0.25, 0.5];
```

### ResizableDivider

Use the `ResizableDivider` class to customize the look and feel of the dividers between each of a container's children.

You can customize the `thickness`, `size`, `indent`, `endIndent`, and `color` of the divider. You can also provide callbacks for the `onHoverEnter` and `onHoverExit` events to respond to user interactions.

```dart
divider: ResizableDivider(
    thickness: 2,
    size: 5,
    indent: 5,
    endIndent: 5,
    onHoverEnter: () => setState(() => hovered = true),
    onHoverExit: () => setState(() => hovered = false),
    color: hovered ? Colors.blue : Colors.black,
),
```

## License

Copyright 2023-2024 Andrew Horn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

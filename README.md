# Flutter Resizable Container

Add flexibility and interaction to your UI with ease.

## Example App

View the interactive example app at [andyhorn.github.io/flutter_resizable_container](https://andyhorn.github.io/flutter_resizable_container)

The example app contains multiple examples demonstrating the features of this package and how to use them.

![Multiple Examples](./doc/screenshot_nav_bar.png?raw=true "Multiple Examples")

Each example also comes with an embedded source-code view, so you don't have to bounce between the app and the repo.

![Source Code Preview](./doc/screenshot_source_code.png?raw=true "Source Code Preview")

## Features

* `ResizableContainer`s are fully nestable
* Customize the size/thickness, indentation, and color of the dividers between children
* Respond to user interactions with `onHoverEnter` and `onHoverExit` callbacks on dividers
* Programmatically set the ratios of the resizable children through a `ResizableController`
* Respond to changes in the sizes of the resizable children by listening to the `ResizableController`

## Getting started

Add this package to your `pubspec.yaml` or install using `flutter pub add`.

```dart
flutter pub add flutter_resizable_container
```

## Usage

### Direction

Add a `ResizableContainer` to your widget tree and give it a `direction` of type `Axis` - this is the direction in which the `children` will be laid out and the direction in which their size will be allowed to flex.

```dart
ResizableContainer(
  direction: Axis.horizontal,
  ...
)
```

In the example above, any children (more on this in the [ResizableChild](#resizable-child) section) will take up the maximum available height while being allowed to flex their width by dragging a divider or updating their ratios via the controller (see below).

### ResizableController

#### Setup

If you wish to respond to changes in sizes or to programmatically adjust child sizes, create a `ResizableController` and keep a reference to it; then, pass it to the `ResizableContainer`'s constructor.

For example:

```dart
final controller = ResizableController();

...

ResizableContainer(
    controller: controller,
),
```

#### Using a ResizableController

Using the controller, you can listen to changes as well as programmatically set the sizes of the container's children.

```dart
final controller = ResizableController();

@override
void initState() {
    super.initState();

    controller.addListener(() {
        // ... react to size change events
        final List<double> sizes = controller.sizes;
        print(sizes.join(', '));
    });
}

@override
void dispose() {
    controller.dispose(); // don't forget to dispose your controller
    super.dispose();
}

// (somewhere else in your code)
// use the `setSizes` method to programmatically set the sizes of the 
// container's children.
//
// This method takes a list of ResizableSize objects - more on this below.
onTap: () => controller.setSizes(const [
    ResizableSize.ratio(0.25),
    ResizableSize.ratio(0.25),
    ResizableSize.ratio(0.5),
]);
```

### ResizableChild

To add widgets to your container, you must provide a `List<ResizableChild>`, each of which contain the child `Widget` as well as some configuration parameters.

```dart
children: [
    if (showNavBar) ...[
        const ResizableChild(
            maxSize: 350.0,
            child: NavBarWidget(),
        ),
    ],
    const ResizableChild(
        startingSize: ResizableSize.expand(),
        child: BodyWidget(),
    ),
    if (showSidePanel) ...[
        const ResizableChild(
            size: ResizableSize.ratio(0.25),
            minSize: 100,
            child: SidePanelWidget(),
        ),
    ],
],
```

In the example above, there are three `Widget`s added to the screen, two of which can be hidden based on state.

The first child, containing the `NavBarWidget`, has a maximum size of 350.0 px.
The second child, containing the `BodyWidget`, is set to automatically expand via the `ResizableSize.expand()` value.
The third child, containing the `SidePanelWidget`, is set to a ratio of 0.75 with a minimum size of 100.0 logical pixels.

The `maxSize` parameter constrains the child and will prevent it from being expanded beyond that size in the `direction` of the container.

The `minSize` parameter constrains the child and will prevent it from being _shrunk_ beyond that size in the `direction` of the container.

The `size` parameter gives a directive of how to size the child during its initial layout and during screen size changes. See the [Resizable Size](#resizable-size) section below for more information.

### ResizableSize

The `ResizableSize` class defines a "size" as either a ratio of the available space, using the `.ratio` constructor, an absolute size in logical pixels, using the `.pixels` constructor, or as an auto-expanding size using the `expand` constructor.

For example, to create a size equal to half of the available space:

```dart
const half = ResizableSize.ratio(0.5);
```

To create a size of 300px:

```dart
const threeHundredPixels = ResizableSize.pixels(300);
```

To allow a child to fill any remaining space:

```dart
const expandable = ResizableSize.expand();
```

#### Size Hierarchy

When the controller is laying out the sizes of children, it uses the following rules:

1. If a child has a size using pixels, it will be given that amount of space
2. If a child has a size using a ratio, it will be given the proportionate amount of the _remaining_ space _after_ all pixel-sizes have been allocated
3. If a child has a size using `expand`, it will be given whatever space is left after the allocations in rule 1 and rule 2 - If there are multiple children using `expand`, the space remaining after the allocations in rule 1 and rule 2 will be evenly distributed between them

##### Example 1

Take the following list:

```dart
// available space = 500px
controller.setSizes(const [
    ResizableSize.pixels(300),
    ResizableSize.ratio(0.25),
    ResizableSize.ratio(0.5),
]);
```

When the controller is allocating space, the first child will be given 300px, leaving 200px of available space.

The second child will be given 1/4 of the remaining 200px, equal to 50px.

The third child will be given 1/2 of the remaining 200px, equal to 100px.

**Note:** In this scenario, there will be 50px of "unclaimed" space.

##### Example 2

Another way of distributing space could be:

```dart
// available space = 500px
controller.setSizes(const [
    ResizableSize.pixels(300),
    ResizableSize.expand(),
    ResizableSize.ratio(0.25),
]);
```

In this example, the first child will be given 300px, leaving 200px of available space.

The third child will be given 1/4 of the remaining 200px, equaling 50px.

The second child will be given the space remaining after the other allocations, equaling 150px.

##### Example 3

```dart
// available space = 500px
controller.setSizes(const [
    ResizableSize.pixels(300),
    ResizableSize.expand(),
    ResizableSize.expand(),
]);
```

In this scenario, the first child will be given 300px, leaving 200px of available space.

The remaining 200px will be evenly distributed between the `expand` children, resulting in each child being given a size of 100px.

###### Flex

The `ResizableSize.expand` constructor takes an optional `flex` parameter of type `int`. If there are multiple `expand` sizes, the available space will be divided by total flex count and then distributed to the children according to their individual flex values - this is the same as the `Flexible` and `Expanded` widgets.

For example:

```dart
ResizableChild(
    size: ResizableSize.expand(flex: 2),
),
ResizableChild(
    size: ResizableSize.expand(), // defaults to flex: 1
),
```

In this scenario, the first child would be given 2/3 of the total available space while the second child received 1/3.

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

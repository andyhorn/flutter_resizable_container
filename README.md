# Flutter Resizable Container

Add flexibility and interaction to your UI with ease.

## Example App

View the interactive example app at [andyhorn.github.io/flutter_resizable_container](https://andyhorn.github.io/flutter_resizable_container)

The example app contains multiple examples demonstrating the features of this package and how to use them.

![Multiple Examples](./doc/screenshot_nav_bar.png?raw=true 'Multiple Examples')

Each example also comes with an embedded source-code view, so you don't have to bounce between the app and the repo.

![Source Code Preview](./doc/screenshot_source_code.png?raw=true 'Source Code Preview')

## Features

- `ResizableContainer`s are fully nestable and support LTR _and_ RTL layouts
- Customize the length, thickness, alignment, and color of the divider(s) between children and the cursor displayed when hovering
- Respond to user interactions with `onHoverEnter` and `onHoverExit` for web/desktop and `onTapDown` and `onTapUp` for mobile
- Programmatically set the sizes of the children through a `ResizableController`
- Respond to changes in the sizes of the resizable children by listening to the `ResizableController`

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

In the example above, any children (more on this in the [ResizableChild](#resizable-child) section) will take up the maximum available height while being allowed to adjust their widths.

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
        final List<double> pixels = controller.pixels;
        print(pixels.join(', '));
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
    ResizableSize.pixels(250),
    ResizableSize.ratio(0.25),
    ResizableSize.expand(),
]);
```

### ResizableChild

To add widgets to your container, you must provide a `List<ResizableChild>`, each of which contain the child `Widget` as well as some configuration.

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

The `ResizableSize` class defines a "size" as either a ratio of the available space, using the `.ratio` constructor, an absolute size in logical pixels, using the `.pixels` constructor, or as an auto-expanding size using the `expand` constructor. A fourth size, `shrink`, will conform to the natural size of its child. 

**Note:** When using `shrink`, the rendering engine will throw an error if its child does not have a natural size, such as a `LayoutBuilder`.

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
2. If a child has a `shrink` size, it will be laid out and given its natural size
3. If a child has a size using a ratio, it will be given the proportionate amount of the _remaining_ space _after_ all pixel- and shrink-sizes have been allocated
4. If a child has a size using `expand`, it will be given whatever space is left after the allocations in the previous steps - If there are multiple children using `expand`, the remaining space will be distributed between them based on their `flex` value (similar to `Expanded` widgets)

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

You can customize the `thickness`, `length`, `crossAxisAlignment`, `mainAxisAlignment`, and `color` of the divider, as well as display a custom mouse cursor on hover. You can also provide callbacks for the `onHoverEnter` and `onHoverExit` (web) and `onTapDown` and `onTapUp` (mobile) events to respond to user interactions.

```dart
divider: ResizableDivider(
    thickness: 2,
    padding: 5,
    length: const ResizableSize.ratio(0.25),
    onHoverEnter: () => setState(() => hovered = true),
    onHoverExit: () => setState(() => hovered = false),
    color: hovered ? Colors.blue : Colors.black,
    cursor: SystemMouseCursors.grab,
),
```

# Sizing

The `thickness` and `length` properties control the size of the line drawn on the screen. The `length` determines the cross-axis size - how "long" the line is - while `thickness` determines the main-axis size. The `length` property is of type `ResizableSize`, giving you the flexibility to set a responsive size, using `.ratio`, or a fixed size, using `.pixels`.

Note: If you set an absolute length that is smaller than the available space, the divider will fit to the available space and not overflow.

# Alignment and padding

If the divider's length is less than the total available space, you can use the `crossAxisAlignment` to control its cross-axis position. For example, a vertical divider set to `CrossAxisAlignment.start` will be positioned at the top of its space. The default value is `.center`.

![Cross-Axis Alignment](./doc/screenshot_cross_axis_start.png?raw=true 'Cross-Axis Alignment')

By adding a `padding` value, additional (empty) space will be added around/alongside the divider. The `mainAxisAlignment` property can then be used to control its position within this space on the main axis. For example, a vertical divider set to `MainAxisAlignment.start` will be positioned at the very left edge of its available space.

![Main-Axis Alignment](./doc/screenshot_main_axis_start.png?raw=true 'Main-Axis Alignment')

## License

Copyright 2023-2024 Andrew Horn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

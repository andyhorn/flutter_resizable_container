## 4.0.0

Stable release of v4 with all changes of prior beta releases.

## 4.0.0-beta.4

- Account for expand sizes with min/max bounds
- Prevent the controller from notifying its listeners during layout/init
- Make `ResizableSize` subclasses' constructor's private
- Improve doc comments

## 4.0.0-beta.3

- Move the min/max bounds out of the `ResizableChild` and into the `ResizableSize`
- Remove the `divider` property of the `ResizableContainer` and add it into the `ResizableChild`
- Add a `cursor` property to the `ResizableDivider` to display a custom `MouseCursor` when hovering over the divider

## 4.0.0-beta.2

- Add a `ResizableLayout` widget that uses a custom `RenderObject` to handle the initial layout and the layout after any properties on the `ResizableContainer` are updated.

## 4.0.0-beta.1

- Rewrite the Controller/Container logic to allow Flutter to handle the initial layout of all widgets, updating the rendered sizes in the controller after the first frame. This _shouldn't_ have any major impact to the API, but it does introduce the use of Timers, which could affect tests.
- Rename `ResizableController.sizes` to `ResizableController.pixels` to more clearly indicate its value.
- Store, expose, and utilize the current list of `ResizableSize` values in the controller. This enables the values to be used even after manually updating them.

## 3.0.4

- Fix a bug/add support for RTL Directionality.

## 3.0.3

- Reinstate the removed `ResizableControllerManager#setChildren` method. This method was removed because the method it targets on the controller was made public. However, the package version was incorrectly bumped since this could be a breaking change. This patch reinstates the method, fixing the breaking change, but adds a deprecation warning in favor of the public controller method.

## 3.0.2

- Make the "setChildren" method of the ResizableContainer public to address a limitation that was causing the "children length equals sizes length" assertions to fail (#61).

## 3.0.1

- Fix a bug causing negative values in a BoxConstraint, which was throwing an AssertionError (#60).

## 3.0.0

After much feedback, I revised the `ResizableContainerDivider` to be even more customizable. The changes include:

1. Replace the `size`, `indent`, and `endIndent` properties with a `length` property, of type `ResizableSize`, to control how long the dividing line is
2. Add `crossAxisAlignment` and `mainAxisAlignment` properties to control where the line sits in its available space (if the line does not take up its full length and/or has padding, see below).
3. Add a `padding` property to add empty space along the main axis - the divider sits within, or alongside, this empty space

## 2.0.0

New major version! See the beta notes below.

## 2.0.0-beta.4

- Fix a bug in the "available size" initialization that was throwing a "marked dirty during build" exception

## 2.0.0-beta.3

- Add a `ResizableSize.expand` constructor that takes a `flex` integer (defaults to 1)
- Remove the optionality of the `size` parameter in `ResizableChild` and use a default `ResizableSize.expand()` value
- Adjust the controller to disallow `null` values for `ResizableSize` arguments
- Adjust the controller to prioritize modifying `ResizableSize.expand` children when scaling the window (up or down) over the `pixel` and `ratio` children, unless no `expand` children are set

## 2.0.0-beta.2

- Added a new `ResizableSize` class that defines a "size" in pixels or as a ratio
- Changed the `startingRatio` in the `ResizableChild` to `startingSize` that takes an optional `ResizableSize`
  - This change allows the starting size of a child to be defined as an absolute value (in logical pixels) or as a ratio of the available space
  - If there is a mixture of pixels and ratio sizes, the pixel sizes will be given priority and then the ratio sizes will be given the remaining available space
- Added a `setSizes` method to the `ResizableController` that takes a list of optional `ResizableSize`s. These sizes will be applied to the current children following the same rules as noted above
- Removed the `ratios` setter in favor of the new `setSizes` method
- Made the controller an optional param in the `ResizableContainer` ctor

## 2.0.0-beta.1

- Renamed `ResizableChildData` to `ResizableChild`
- Added an `expand` flag to the `ResizableChild` ctor
  - If there is a `startingRatio` set and this flag is `true`, the child will automatically expand to fill any remaining available space. If this flag is `false`, the child will only expand to meet its `startingRatio` constraint
  - If the `startingRatio` is `null`, the child will automatically expand to fill any remaining available space, regardless of whether or not this flag is set
- Move the list of `ResizableChild` objects out of the `ResizableController` and _back_ into the `ResizableContainer` as the `children` parameter
  - This allows the list of children to be modified on-the-fly without recreating a `ResizableController`

## 1.0.0

First stable version!

- Encapsulation of divider configuration in a new `ResizableDivider` class
  - Divider `thickness` and `size` properties, mirroring the Flutter Divider's `thickness` and `width` properties, have been added
  - `onHoverEnter` and `onHoverExit` callbacks allow you to react to the user's interactions with the divider
- All size tracking and calculations have been moved out of the `ResizableContainer` widget and into the `ResizableController`
  - This fixed several bugs and improves performance by converting the `ResizableContainer` to a `StatelessWidget` (from stateful)
- `ResizableContainer` now requires a `List<Widget>` as its `children` property, as the `List<ResizableChildData>` have been moved into the `ResizableController`
- Added and improved tests
- Added a GH workflow to deploy the example app to GH Pages

## 0.5.0

- Adds `dividerIndent` and `dividerEndIndent` properties to the resizable container

## 0.4.2

- Fixes an issue with the `didUpdateWidget` lifecycle hook causing errors to be thrown during hot-reloads

## 0.4.1

- Add tests for `ResizableController`
- Add tests for `ResizableContainer`
- Add GitHub Actions workflow

## 0.4.0

- Add `ResizableController` to allow programmatic control of resizable children
- Fix a bug causing adjacent containers to grow in size when the target container reaches is minimum size

## 0.3.0

- Make divider color and width customizable

## 0.2.1

- Fix package description to improve pub.dev score

## 0.2.0

- Update the Dart SDK constraints to >=3.0.0 <4.0.0

## 0.1.3

- Fix a bug causing overflows when the window is resized
- Remove the factory and add the debug assert directly to the ctor

## 0.1.2

- Remove commented code from the example project

## 0.1.1

- Improve documentation and comments

## 0.1.0

- Rework dividers to lie in-line with child widgets, taking up space
  along the primary axis, instead of being placed in a stack and positioned
  according to the child sizes
- Add a custom divider who's width is known and can be controlled to ease
  calculating the available space for child widgets
- Remove the optionality of the divider - this widget is now required to be
  visible, as hiding it would disable the resize functionality

## 0.0.5

- Fix divider and cursor positioning

## 0.0.4

- Add optional divider line
- Fix a bug allowing child sizes to grow beyond available space
- Improve example with switchable direction and toggle-able divider

## 0.0.3

- Add example to README
- Add example project
- Fix a bug allowing negative child sizes

## 0.0.2

- Fix a typo in the README

## 0.0.1

**Initial Release**

- Container resizes and enforces child size constraints (if present)
- Resize cursor responds to user clicks and drags on web

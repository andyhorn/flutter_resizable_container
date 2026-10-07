## 4.2.0

- Added `cascadeNegativeDelta` flag to cascade changes through children that have reached their lower bound.
- Added `onDragStart` and `onDragEnd` callbacks to the `ResizableDivider`.
- Added a `key` parameter to the `ResizableChild` to pass to the child Widget's wrapper.
- Bump FVM Flutter and dependency versions.

## [4.3.0](https://github.com/andyhorn/flutter_resizable_container/compare/v4.2.0...v4.3.0) (2026-10-07)


### Features

* add hide/show methods to ResizableController ([#99](https://github.com/andyhorn/flutter_resizable_container/issues/99)) ([6e466da](https://github.com/andyhorn/flutter_resizable_container/commit/6e466da4a33031cb711497808bd30418767e9dfc))
* animate hide/show child transitions ([#123](https://github.com/andyhorn/flutter_resizable_container/issues/123)) ([7d49e47](https://github.com/andyhorn/flutter_resizable_container/commit/7d49e4713e44df9629ff132188a4a331491e1304))
* lock individual dividers or the whole container ([#73](https://github.com/andyhorn/flutter_resizable_container/issues/73)) ([#128](https://github.com/andyhorn/flutter_resizable_container/issues/128)) ([86ddefe](https://github.com/andyhorn/flutter_resizable_container/commit/86ddefe15937aab969815ff0ac71146128609d1b))


### Bug Fixes

* clamp cascaded delta by receiver max constraint ([#106](https://github.com/andyhorn/flutter_resizable_container/issues/106)) ([#125](https://github.com/andyhorn/flutter_resizable_container/issues/125)) ([9f06c32](https://github.com/andyhorn/flutter_resizable_container/commit/9f06c324304907c0feeb92af7b6d5fd7cadeec80))
* direction comparison in resizable container ([#95](https://github.com/andyhorn/flutter_resizable_container/issues/95)) ([93f458f](https://github.com/andyhorn/flutter_resizable_container/commit/93f458f3e99ba481b29c64291d8b30bf1de4de9b))
* include min/max in ResizableSize equality ([#104](https://github.com/andyhorn/flutter_resizable_container/issues/104)) ([#127](https://github.com/andyhorn/flutter_resizable_container/issues/127)) ([72c28ae](https://github.com/andyhorn/flutter_resizable_container/commit/72c28ae5119186b8522f7f8f18844e00f1f7b453))
* measure shrink children via dry layout ([#85](https://github.com/andyhorn/flutter_resizable_container/issues/85)) ([#98](https://github.com/andyhorn/flutter_resizable_container/issues/98)) ([c6fc50e](https://github.com/andyhorn/flutter_resizable_container/commit/c6fc50e595d5110327e2575c0921c3557a617334))
* rebind controller when widget.controller changes ([#107](https://github.com/andyhorn/flutter_resizable_container/issues/107)) ([#124](https://github.com/andyhorn/flutter_resizable_container/issues/124)) ([8e7add0](https://github.com/andyhorn/flutter_resizable_container/commit/8e7add00598858e5234999966f656650be2e5f8d))
* ResizableChild.props omits divider and discards child widget ([#126](https://github.com/andyhorn/flutter_resizable_container/issues/126)) ([059d437](https://github.com/andyhorn/flutter_resizable_container/commit/059d437b954b94ce5c2c38efe91eabe24e5eb1df))


### Performance Improvements

* replace Decimal arithmetic in expand layout with doubles ([#121](https://github.com/andyhorn/flutter_resizable_container/issues/121)) ([#132](https://github.com/andyhorn/flutter_resizable_container/issues/132)) ([0b8cce4](https://github.com/andyhorn/flutter_resizable_container/commit/0b8cce4f3ab9ef974a1dc7659a4c09589a07cae1))


### Build System

* **deps:** bump equatable from 2.1.0 to 3.0.0 ([#135](https://github.com/andyhorn/flutter_resizable_container/issues/135)) ([0e75861](https://github.com/andyhorn/flutter_resizable_container/commit/0e75861f689dbe4f99ce60faa93508762fcd7425))
* **deps:** bump flutter_lints from 5.0.0 to 6.0.0 ([#91](https://github.com/andyhorn/flutter_resizable_container/issues/91)) ([9a7a6a9](https://github.com/andyhorn/flutter_resizable_container/commit/9a7a6a958f1f011b653503e220932924fc64d6fe))

## 4.1.0

- Improved change detection in the container to enable more accurate rebuilds when children change.

## 4.0.1

- Fixed a bug causing a custom divider with interactions to break resizing.

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

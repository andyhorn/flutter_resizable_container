## 4.2.0

- Added `cascadeNegativeDelta` flag to cascade changes through children that have reached their lower bound.
- Added `onDragStart` and `onDragEnd` callbacks to the `ResizableDivider`.
- Added a `key` parameter to the `ResizableChild` to pass to the child Widget's wrapper.
- Bump FVM Flutter and dependency versions.

## [4.3.0](https://github.com/andyhorn/flutter_resizable_container/compare/v4.2.0...v4.3.0) (2026-05-27)


### Features

* Add divider (end)indent ([#24](https://github.com/andyhorn/flutter_resizable_container/issues/24)) ([9be3833](https://github.com/andyhorn/flutter_resizable_container/commit/9be38332e470999f85d0f9fba66a48c63912bb56))
* Add expand/flex sizing ([#41](https://github.com/andyhorn/flutter_resizable_container/issues/41)) ([ceccf00](https://github.com/andyhorn/flutter_resizable_container/commit/ceccf001df1a133916f3a56ce088e55e6c2232bd))
* add hide/show methods to ResizableController ([#99](https://github.com/andyhorn/flutter_resizable_container/issues/99)) ([6e466da](https://github.com/andyhorn/flutter_resizable_container/commit/6e466da4a33031cb711497808bd30418767e9dfc))
* add support for OnTapUp and OnTapDown callbacks for mobile ([#51](https://github.com/andyhorn/flutter_resizable_container/issues/51)) ([92bdff4](https://github.com/andyhorn/flutter_resizable_container/commit/92bdff44141ef32a9fd94b50da79a40a018a930e))
* Add version to example ([#33](https://github.com/andyhorn/flutter_resizable_container/issues/33)) ([34735e0](https://github.com/andyhorn/flutter_resizable_container/commit/34735e0a5575c40b4351a641448f1632e9acbe37))
* animate hide/show child transitions ([#123](https://github.com/andyhorn/flutter_resizable_container/issues/123)) ([7d49e47](https://github.com/andyhorn/flutter_resizable_container/commit/7d49e4713e44df9629ff132188a4a331491e1304))
* Build layout using custom render object ([#68](https://github.com/andyhorn/flutter_resizable_container/issues/68)) ([671d01e](https://github.com/andyhorn/flutter_resizable_container/commit/671d01ef6cfce4a341a0cb5cb2f75612ab7234c6))
* cascade negative deltas ([#88](https://github.com/andyhorn/flutter_resizable_container/issues/88)) ([4b409a1](https://github.com/andyhorn/flutter_resizable_container/commit/4b409a1eda31d4b57f93c720235ddf34982fc8a5))
* Controller v2 ([#25](https://github.com/andyhorn/flutter_resizable_container/issues/25)) ([e182ca7](https://github.com/andyhorn/flutter_resizable_container/commit/e182ca76d15b8a22306d69450a8a11afbc31aa74))
* Convert sizing to ResizableSize ([#38](https://github.com/andyhorn/flutter_resizable_container/issues/38)) ([8f0231f](https://github.com/andyhorn/flutter_resizable_container/commit/8f0231ff794b2aa3d233bc98b74423536d33a90e))
* custom hover cursor ([#74](https://github.com/andyhorn/flutter_resizable_container/issues/74)) ([d8ede1b](https://github.com/andyhorn/flutter_resizable_container/commit/d8ede1b531abba76bc4d15af10661ae93d17f78b))
* Divider hover ([#28](https://github.com/andyhorn/flutter_resizable_container/issues/28)) ([4217011](https://github.com/andyhorn/flutter_resizable_container/commit/4217011121703e7254e5f710bd3d1e31057ada70))
* drag events ([#89](https://github.com/andyhorn/flutter_resizable_container/issues/89)) ([b8714e0](https://github.com/andyhorn/flutter_resizable_container/commit/b8714e0ce36b5daa6f0b5aea4ba47cde985e3f75))
* improve change detection ([ac0c717](https://github.com/andyhorn/flutter_resizable_container/commit/ac0c7178c7f62b5d9b05e16d294b3ee1e3c562a6))
* improve new example ([68ef2d6](https://github.com/andyhorn/flutter_resizable_container/commit/68ef2d6c028284dc71e766d3b4f0df89ed642217))
* lock individual dividers or the whole container ([#73](https://github.com/andyhorn/flutter_resizable_container/issues/73)) ([#128](https://github.com/andyhorn/flutter_resizable_container/issues/128)) ([86ddefe](https://github.com/andyhorn/flutter_resizable_container/commit/86ddefe15937aab969815ff0ac71146128609d1b))
* Make the controller optional ([#40](https://github.com/andyhorn/flutter_resizable_container/issues/40)) ([88ae992](https://github.com/andyhorn/flutter_resizable_container/commit/88ae99254d775090379d7d8b02a7c869a9839c00))
* Move children to container; add expand flag ([#31](https://github.com/andyhorn/flutter_resizable_container/issues/31)) ([6b53ea6](https://github.com/andyhorn/flutter_resizable_container/commit/6b53ea677c870e8458806247e487bb545e1b1ea1))
* remove unnecessary key ([4ee29ce](https://github.com/andyhorn/flutter_resizable_container/commit/4ee29ce6d60d0554aa29117810e36248df32da2f))
* Shrink ([#56](https://github.com/andyhorn/flutter_resizable_container/issues/56)) ([d7ddaf4](https://github.com/andyhorn/flutter_resizable_container/commit/d7ddaf4f3c73cc47060ca3e708d9337de58c9bea))


### Bug Fixes

* account for expand min/max bounds ([#82](https://github.com/andyhorn/flutter_resizable_container/issues/82)) ([b7506d5](https://github.com/andyhorn/flutter_resizable_container/commit/b7506d5761ae4af3eb5a8f3085330f260bd35fb8))
* Box constraints assertion error when reducing screen size ([#60](https://github.com/andyhorn/flutter_resizable_container/issues/60)) ([140c0a3](https://github.com/andyhorn/flutter_resizable_container/commit/140c0a34355ac83eae4b08b13504236aa352c039)), closes [#58](https://github.com/andyhorn/flutter_resizable_container/issues/58)
* clamp cascaded delta by receiver max constraint ([#106](https://github.com/andyhorn/flutter_resizable_container/issues/106)) ([#125](https://github.com/andyhorn/flutter_resizable_container/issues/125)) ([9f06c32](https://github.com/andyhorn/flutter_resizable_container/commit/9f06c324304907c0feeb92af7b6d5fd7cadeec80))
* controller notifying during build ([#81](https://github.com/andyhorn/flutter_resizable_container/issues/81)) ([b88bcc7](https://github.com/andyhorn/flutter_resizable_container/commit/b88bcc7272c05444baff284c47c2fa1345322136))
* custom divider ([#87](https://github.com/andyhorn/flutter_resizable_container/issues/87)) ([7d5e7df](https://github.com/andyhorn/flutter_resizable_container/commit/7d5e7dfba8f28d3abca9494e3140b990e1846a13))
* Dart SDK constraint ([#43](https://github.com/andyhorn/flutter_resizable_container/issues/43)) ([c11bbfb](https://github.com/andyhorn/flutter_resizable_container/commit/c11bbfb5a9a8839dfd1ade61aba6dda938ae2de6))
* direction comparison in resizable container ([#95](https://github.com/andyhorn/flutter_resizable_container/issues/95)) ([93f458f](https://github.com/andyhorn/flutter_resizable_container/commit/93f458f3e99ba481b29c64291d8b30bf1de4de9b))
* divider and cursor positioning ([457241a](https://github.com/andyhorn/flutter_resizable_container/commit/457241a27f7544f658168ce0be08eaf36554c719))
* don't allow children to grow beyond available space ([7c30d85](https://github.com/andyhorn/flutter_resizable_container/commit/7c30d85bdd6efbe872418596ee2650c10a8c10d0))
* don't allow children to shrink below 0 in size ([7fbcc55](https://github.com/andyhorn/flutter_resizable_container/commit/7fbcc556a00c88bb8dd7ecb691626282bdbd7ea3))
* ensure child sizes cannot be below zero ([8ee51a3](https://github.com/andyhorn/flutter_resizable_container/commit/8ee51a3558a9edf7b660b56a632bd2bd78a1089a))
* Fix versioning syntax ([#34](https://github.com/andyhorn/flutter_resizable_container/issues/34)) ([df020c8](https://github.com/andyhorn/flutter_resizable_container/commit/df020c87e084d7e032b6ecaa7285267b46327657))
* Hot reload ([#23](https://github.com/andyhorn/flutter_resizable_container/issues/23)) ([4c35e5a](https://github.com/andyhorn/flutter_resizable_container/commit/4c35e5a309b29d25032e2a9b9944c57a38ce5f6b))
* include min/max in ResizableSize equality ([#104](https://github.com/andyhorn/flutter_resizable_container/issues/104)) ([#127](https://github.com/andyhorn/flutter_resizable_container/issues/127)) ([72c28ae](https://github.com/andyhorn/flutter_resizable_container/commit/72c28ae5119186b8522f7f8f18844e00f1f7b453))
* incorporate divider sizes into calculations ([d67d22e](https://github.com/andyhorn/flutter_resizable_container/commit/d67d22e0df97fd79dbdd12834557ef9abc58119e))
* Marked dirty during build exception ([#44](https://github.com/andyhorn/flutter_resizable_container/issues/44)) ([4a02b58](https://github.com/andyhorn/flutter_resizable_container/commit/4a02b58b8af90ff6efbfa29842ba914b31e89e3f))
* measure shrink children via dry layout ([#85](https://github.com/andyhorn/flutter_resizable_container/issues/85)) ([#98](https://github.com/andyhorn/flutter_resizable_container/issues/98)) ([c6fc50e](https://github.com/andyhorn/flutter_resizable_container/commit/c6fc50e595d5110327e2575c0921c3557a617334))
* rebind controller when widget.controller changes ([#107](https://github.com/andyhorn/flutter_resizable_container/issues/107)) ([#124](https://github.com/andyhorn/flutter_resizable_container/issues/124)) ([8e7add0](https://github.com/andyhorn/flutter_resizable_container/commit/8e7add00598858e5234999966f656650be2e5f8d))
* ResizableChild.props omits divider and discards child widget ([#126](https://github.com/andyhorn/flutter_resizable_container/issues/126)) ([059d437](https://github.com/andyhorn/flutter_resizable_container/commit/059d437b954b94ce5c2c38efe91eabe24e5eb1df))
* toggle button text color ([d16aa95](https://github.com/andyhorn/flutter_resizable_container/commit/d16aa957889729f207e3c4c39ae0ebadbc46f6d8))
* typo in README ([af616fc](https://github.com/andyhorn/flutter_resizable_container/commit/af616fc8e58d7001c549253cebdb3ff8021f4af4))
* vertical cross-axis sizing ([27268ae](https://github.com/andyhorn/flutter_resizable_container/commit/27268ae4ae989e4e18df7ce444b4e0d6c4dbb4e7))


### Documentation

* add bmac link ([aee9ec8](https://github.com/andyhorn/flutter_resizable_container/commit/aee9ec8aaa60df305cd7b04548ba7471320b83e9))
* Add example GIFs ([e994b96](https://github.com/andyhorn/flutter_resizable_container/commit/e994b96dc3c70de2f8c9f706a17b0630390f84c4))
* Add GH Pages workflow ([#27](https://github.com/andyhorn/flutter_resizable_container/issues/27)) ([c03a2f5](https://github.com/andyhorn/flutter_resizable_container/commit/c03a2f579a8dcbfa6f517a8ab55f39b86aa372fa))
* Beta release docs ([#32](https://github.com/andyhorn/flutter_resizable_container/issues/32)) ([42faa9a](https://github.com/andyhorn/flutter_resizable_container/commit/42faa9a9395fc05cac93ddb75eb75ba6ac950ffa))
* fix heading style in README ([e312834](https://github.com/andyhorn/flutter_resizable_container/commit/e31283426d3a159bb509262a25048460d15a2dab))
* update CHANGELOG ([b9cf13b](https://github.com/andyhorn/flutter_resizable_container/commit/b9cf13b25d8738dd0cfeba6cfd83327c36bf24fa))
* update CHANGELOG for v4 ([2ffa0b6](https://github.com/andyhorn/flutter_resizable_container/commit/2ffa0b6bedb718dc8970b6d95162f4c80e1e9a51))
* update README for cascade flag ([a7743b4](https://github.com/andyhorn/flutter_resizable_container/commit/a7743b4ee9dcde67546f65c48d332b44ea3cbc23))


### Build System

* **deps:** bump flutter_lints from 3.0.2 to 4.0.0 ([#36](https://github.com/andyhorn/flutter_resizable_container/issues/36)) ([4f615bc](https://github.com/andyhorn/flutter_resizable_container/commit/4f615bc388d9c0b30bcef029dd5ed70b9dba5fba))
* **deps:** bump flutter_lints from 4.0.0 to 5.0.0 ([#53](https://github.com/andyhorn/flutter_resizable_container/issues/53)) ([001fa27](https://github.com/andyhorn/flutter_resizable_container/commit/001fa271eb550822ccb83b9eb1cb3cfb729e63d0))
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

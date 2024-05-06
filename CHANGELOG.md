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

**TODO**

  - Add documentation, code comments, and examples  

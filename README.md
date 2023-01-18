Add resizable containers to your Flutter project.

## Features

Builds a `Flex` container with two or more children and a `direction`, then allows your users to adjust the size of each child with a simple tap/click and drag.

## Getting started

Simply install the package like you would any other Flutter package:

```dart
flutter pub add flutter_resizable_container
```

## Usage

First, add a `ResizableContainer` to your widget tree and give it a `direction` of type `Axis`: this is the direction in which the child objects will be laid out and the direction in which the children's size will flex.

Second, add a list of `ResizableChildData` containing values for each child:

  * `child: Widget` - this is the child widget that will be contained and who's size will be changed
  * `startingRatio: double` - this ratio will be used to determine the child's initial size, based on the available space of the parent `ResizableContainer`. 
    
    **Note**: this value is required for each child and the total sum of all a containers child ratios must equal `1.0`

  * `minSize: double?` (optional) - this value indicates the absolute minimum size this child should take; any adjustments that would reduce the child's size below this value will be rejected
  * `maxSize: double?` (optional) - similar to the [minSize], this indicates the absolute maximum size the child should take; any adjustments that would increase the child's size above this value will be rejected

## License

Copyright 2023 Andrew Horn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

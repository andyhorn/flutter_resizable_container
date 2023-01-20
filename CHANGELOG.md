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

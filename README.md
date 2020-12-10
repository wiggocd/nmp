nmp - The New Music Player

Written with AppKit in Swift 5

## Prerequisites

- Xcode 11.7+ command line tools
- Carthage
  - Homebrew to install Carthage if not installed

<sub>Run:</sub>

`xcode-select --install` If the command line tools are not already installed

If brew is not installed, follow the instructions at [Homebrew](http://brew.sh)

`brew install carthage` If Carthage is not installed

`carthage update`


## Building

`xcodebuild build` 

An application package should be built to `build/Release/nmp.app`

You can also open up `nmp.xcodeproj` in Xcode or higher and change the build team / signing to build on your machine.

_______

The aim of this project is to create a clean audio playback program using AppKit to render an application targeted for local file playback with a native appearance.

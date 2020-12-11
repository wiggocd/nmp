nmp - The New Music Player

For macOS 10.15+

Swift 5 & Cocoa

## Usage

To download an application package, go to the releases section. For optimal results, load your music from your home music folder.

## Prerequisites to Build

- Xcode 11.7 or higher from the App Store or [Apple Developer](https://developer.apple.com)
- Carthage
  - Homebrew to install Carthage if not installed

<sub>Run:</sub>

Xcode first if the additional components are not installed

`xcode-select --install` or try going into Xcode > Preferences > Locations and select the command line tools to install them

If brew is not installed, follow the instructions at [Homebrew](https://brew.sh)

`brew install carthage` If Carthage is not installed

`carthage update`


## Building

Open up `nmp.xcodeproj` in Xcode and change the build team / signing to build on your machine. To build for deployment, go to Product > Archive in the Xcode project.

Run `xcodebuild build` to build: an application package should be built to `build/Release/nmp.app`

_______

The aim of this project is to create an audio playback program targeted for local files with a native appearance.

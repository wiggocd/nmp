nmp - The New Music Player for macOS 10.15+

[Website](https://gothgirl68k.github.io/nmp)

## Usage

To download an application package, go to the releases page.


## Prerequisites to Build

- Xcode 12.0 or higher from the App Store or from [Apple Developer](https://developer.apple.com/xcode/resources/)

<sub>Run:</sub>

Xcode first if the additional components are not installed

`xcode-select --install` or try going into Xcode > Preferences > Locations and select the command line tools to install them


## Building

Open `nmp.xcodeproj` in Xcode and change the build team / signing info to build on your machine. To build for deployment, go to Product > Archive in the Xcode project.

Run `xcodebuild build` to build; an application package should be built to `build/Release/nmp.app`

_______

The aim of this project is to create an audio playback program targeted for local files with an as similar to native as possible appearance.

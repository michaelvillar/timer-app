# A simple Timer app for Mac

<img src="/screenshots/timer.png?raw=tru" width="262" align="right">

[Download here](https://github.com/michaelvillar/timer-app/releases)

Drag the blue arrow to set a timer. Release to start! Click to pause.

When the time is up, a notification will show up with a nice sound.

Create new timers with `CMD+N`.

Install as a [cask](https://caskroom.github.io) via `brew cask install michaelvillar-timer`.

Inspired by the **great** [Minutes widget](http://minutes.en.softonic.com/mac) from Nitram-nunca I've been using for years. But it wasn't maintained anymore (non-retina) + it was the only widget in my dashboard :)

Timer requires OS X 10.11 or later.

## Build

```
xcodebuild -quiet clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
open build/Release/
```

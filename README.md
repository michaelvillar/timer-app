# A simple Timer app for Mac

<img src="/screenshots/light-mode.png?raw=true" width="262" align="right">

<img src="/screenshots/dark-mode.png?raw=true" width="262" align="right">

[Download here](https://github.com/michaelvillar/timer-app/releases)

Drag the blue arrow to set a timer. Release to start! Click to pause.

When the time is up, a notification will show up with a nice sound.

Create new timers with `CMD+N`.

Install as a [brew cask](https://caskroom.github.io) via 

```shell
brew install --cask michaelvillar-timer
```

Inspired by the **great** [Minutes widget](http://minutes.en.softonic.com/mac) from Nitram-nunca I've been using for years. But it wasn't maintained anymore (non-retina) + it was the only widget in my dashboard :)

Timer requires macOS 10.11 or later.

### Build

```
make
```

### Keyboard Shortcuts

Enter digits to set minutes. A decimal point specifies seconds so `2.34` is 2 minutes and 34 seconds.

<kbd>backspace</kbd> or <kbd>escape</kbd> to edit.
<kbd>enter</kbd> to start or pause the timer.
<kbd>cmd</kbd>+<kbd>n</kbd> to create a new timer.
<kbd>r</kbd> to restart with the last timer.

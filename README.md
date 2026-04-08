# A simple Timer app for Mac

<img src="/screenshots/light-mode.png?raw=true" width="262" align="right">

<img src="/screenshots/dark-mode.png?raw=true" width="262" align="right">

[Download here](https://github.com/michaelvillar/timer-app/releases)

Drag the blue arrow to set a timer. Release to start! Click to pause.

When the time is up, a notification will show up with a nice sound.

Create new timers with `CMD+N`.

Install as a [brew cask](https://caskroom.github.io) via 

```shell
brew install michaelvillar-timer
```

Inspired by the **great** [Minutes widget](http://minutes.en.softonic.com/mac) from Nitram-nunca I've been using for years. But it wasn't maintained anymore (non-retina) + it was the only widget in my dashboard :)

Timer requires macOS 14 (Sonoma) or later.

### Build

```
make
```

### Keyboard Shortcuts

Enter digits to set minutes. A decimal point specifies seconds so `2.34` is 2 minutes and 34 seconds.

| Key | Action |
|-----|--------|
| <kbd>backspace</kbd> or <kbd>escape</kbd> | Edit timer |
| <kbd>enter</kbd> | Start or pause |
| <kbd>cmd</kbd>+<kbd>n</kbd> | New timer |
| <kbd>r</kbd> | Restart with last timer |
| <kbd>+</kbd> or <kbd>↑</kbd> | Add a minute |
| <kbd>-</kbd> or <kbd>↓</kbd> | Subtract a minute |
| <kbd>shift</kbd>+<kbd>+</kbd> or <kbd>shift</kbd>+<kbd>↑</kbd> | Add 10 minutes |
| <kbd>shift</kbd>+<kbd>-</kbd> or <kbd>shift</kbd>+<kbd>↓</kbd> | Subtract 10 minutes |

# Save & See

A minimal macOS menu bar app to store and instantly copy key-value snippets — API keys, tokens, credentials, anything you access frequently.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Lives in the menu bar, out of your way
- Add named snippets (name + value)
- Click any snippet to copy its value instantly
- Swipe to delete
- Data persists across restarts (UserDefaults)
- No Dock icon, no background clutter

## Requirements

- macOS 26 or later
- Xcode 26 (to build from source)

## Install

### Download (easiest)

1. Go to [Releases](../../releases/latest)
2. Download `Save-See.zip`
3. Extract and move `Save&See.app` to `/Applications`
4. First launch: right-click → Open (bypasses Gatekeeper for unsigned builds)

### Build from source

```bash
git clone https://github.com/MehmetAkifff/Save-See.git
cd Save-See
open "Save&See.xcodeproj"
```

Build and run with ⌘R in Xcode.

## Usage

1. Click the clipboard icon in the menu bar
2. Press **+** to add a new snippet — give it a name and a value
3. Click any snippet to **copy its value** to the clipboard
4. Swipe left on a row to delete it

## License

MIT © [Mehmet Akif ERGANİ](https://github.com/MehmetAkifff)

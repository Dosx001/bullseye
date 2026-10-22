# ![logo](pkg/assets/32x32.png) bullseye

![gif](https://i.imgur.com/knQBD4H.gif)

## Shortcuts

| Binding                       | Action                                     |
| ----------------------------- | ------------------------------------------ |
| ESC, q                        | Closes overlay                             |
| a, s, d, f, w, e, i, o, Space | Shrinks overlay to selected area(Area Key) |
| u                             | Undo last area selection                   |
| r                             | Resets all area selections                 |
| h,j,k,l                       | Moves overlay left, down, up, right        |
| Alt + Area Key                | Left-click area                            |
| Ctrl + Area Key               | Right-click area                           |
| Ctrl + Alt + Area Key         | Middle-click area                          |
| Shift + Area Key              | Moves mouse cursor to area                 |
| Alt + ;, ;                    | Left-click on current mouse position       |
| Ctrl + ;                      | Right-click on current mouse position      |
| Ctrl + Alt + ;                | Middle-click on current mouse position     |

## Limitations

Bullseye is currently works for single-monitor setups. When multiple monitors
are connected, it always launches on the primary monitor.

There is no standard, cross-compositor method to detect which monitor the user
is actively working on. Similarly, there is no universal method for moving a
window between monitors across Linux desktop environments and windowing
systems.

## Installation

### Arch Linux (AUR)

```bash
paru -S bullseye
```

### Permissions

Unless you want to run `bullseye` with `sudo` every time, you need to grant
your user read and write access to `/dev/uinput` with:

```bash
sudo setfacl -m "u:$USER:rw" /dev/uinput
```

### Windows and MacOS

Bullseye is only supported on Linux. The legacy version is available at
[https://github.com/Dosx001/bullseye-tauri](https://github.com/Dosx001/bullseye-tauri).

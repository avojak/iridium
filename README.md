# Iridium

![Travis (.com)](https://img.shields.io/travis/com/avojak/iridium.svg)
![GitHub](https://img.shields.io/github/license/avojak/iridium.svg?color=blue)

Iridium is a native Linux IRC client built in Vala and Gtk for elementary OS.

## Install from Source

You can install Iridium by compiling from source. Here's the list of
dependencies required:

- `granite (>= 0.5.1)`
- `debhelper (>= 10.5.1)`
- `gettext`
- `libgtk-3-dev (>= 3.10)`
- `meson`
- `valac (>= 0.28.0)`

## Building

```
$ meson build --prefix=/usr
$ cd build
$ ninja
```

## Running

```
$ sudo ninja install
$ com.github.avojak.iridium
```

### Updating Translations

When new translatable strings are added, ensure that `po/POTFILES` contains a
reference to the file with the translatable string.

Update the `.pot` file which contains the translatable strings:

```
$ ninja com.github.avojak.iridium-pot
```

Generate translations for the languages listed in the `po/LINGUAS` files:

```
$ ninja com.github.avojak.iridium-update-po
```

## Feature TODO List

This project is very much in-progress and has a lot of work left to do. Here is a list of features I plan on implementing that I will update upon completion:

- [x] Automatically open chat views for joined channels and incoming direct messages
- [ ] Support leaving channels and disconnecting from servers
- [ ] Autoscrolling
- [ ] Support authentication for servers
- [ ] Special formatting for usernames and URLs in messages
- [ ] Favorite channels
- [ ] Save and restore state when closing and re-opening
- [ ] Display channel users list
- [ ] Display available channel list
- [ ] Respond to network loss and reconnection

# Iridium

Iridium is a native Linux IRC client build in Vala and Gtk.

## Install from Source

You can install Iridium by compiling from source. Here's the list of
dependencies required:

- debhelper (>= 10.5.1),
- gettext,
- libgtk-3-dev (>= 3.10),
- meson,
- valac (>= 0.28.0)

## Building

```
$ meson build --prefix=/usr
$ cd build
$ ninja
$ sudo ninja install
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

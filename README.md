# i18n for Defold

The core is from https://github.com/kikito/i18n.lua with a little modification to make it a Defold component.

### Some of changes compared to the original one:
- `i18n.load_file(path)` to load from a JSON file (original is `i18n.loadFile` and load from a lua file).
- `i18n.set_locale(locale)` (original is `i18n.setLocale`)

### Notes:
- In order to load from a JSON file, you should set the file or the folder containing it as a custom resource in `game.project`

---

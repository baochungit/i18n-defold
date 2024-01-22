# i18n for Defold

The core is from https://github.com/kikito/i18n.lua with a little modification to make it suitable for Defold.

## Some of changes compared to the original one:
- `i18n.load_file(path)` to load from a JSON file (original is `i18n.loadFile` and load from a lua file).
- `i18n.set_locale(locale)` (original is `i18n.setLocale`)

## Basic usage
Import `i18n` lib
```
local i18n = require("i18n.i18n")
```

You then can load translations from a JSON file
```
i18n.load_file(path/to/your/json/file)
```

Or load from a lua table
```
i18n.load({
  en = {
    hello = "Hello %{name}"
  },
  fr = {
    hello = "Bonjour %{name}"
  }
})
```

After loading translations, you may want to use it at somewhere
```
print(i18n.translate("hello", { name = "Defold" }))
```
Or use the shorter form
```
print(i18n("hello", { name = "Defold" }))
```

The default locale is `en`, you can set it to another one as needed by
```
i18n.set_locale("fr")
```

## Notes:
- In order to load from a JSON file, you should set the file or the folder containing it as a custom resource in `game.project`

---

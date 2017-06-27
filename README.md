## Linkall

Convenient tool to link up local packages.

- respects the used package manager
- automatic recursive install, but only for linked packages
- declarative options on package level

### Install

```bash
npm install -g linkall
```

### Usage

```
usage: linkall [<options>] <folders>

options:
-h, --help          output usage information
-p, --pm <cli>      default package manager (defaults to npm)
-n, --no-install    don't install uninstalled packages
-l, --look-up <dir> additional dir to lookup local packages
-u, --unlink        unlink local packages and install them directly (not implemented yet)
-s, --silent        suppress output of package manager
-v, --verbose       additional output
-t, --test          only show structure

folders is optional and defaults to cwd
```

### Examples

```bash
linkall --test --verbose # should be the first run
linkall --silent --pm pnpm --look-up ../local-package-store .
```

### Options

Default behavior is to link all found dependencies including devDependencies and all peerDependencies from them.
If your needs are more specific, you can give orders within your package.json:
```js
{
    "linkall": [
        // to only link up pkg1 and pk2, if found..
        "pkg1",
        "pkg2"
    ],
    // or
    "linkall": [
        "dev":true, // to include devDeps
        "dep":true  // to include deps
    ]
}
```


## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.

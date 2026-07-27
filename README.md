# Command-line interface for **`mclip`**

Run without any arguments to see the usage message
Config is stored in `$HOME/.config/mclip.json` on Linux/MacOS and `%AppData%\metacli\config.json` on Windows

## Compiling

### Setup
- **For debug builds**
  ```sh
  meson setup .debug --buildtype=debug
  cd .debug
  ```
- **For release builds**
  ```sh
  meson setup .release --buildtype=release
  cd .release
  ```

### Build
```sh
ninja --quiet
./mclip
```

<!-- ### Install -->
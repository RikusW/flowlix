# Patches

These are applied (in numeric order) to the pinned `external/FlowtoysUpdater`
submodule by either the container build (`Dockerfile`) or the native build
(`scripts/build-in-place.sh`). They are plain `git diff` output and apply with
either `git apply` or `patch -p1`; the native script skips patches that are
already applied.

| Patch | File(s) | Why |
|-------|---------|-----|
| `0001-appupdater-juce547-and-linux-noautoupdate.patch` | `Source/AppUpdater.cpp` | Two changes: (a) `URL::downloadToFile()` returns a raw `DownloadTask*` in JUCE 5.4.7, so wrap it in the `unique_ptr`; (b) on Linux, disable auto-update — the "new version" dialog becomes informational ("install via your package manager") with only a Close button, no download/install. |
| `0002-firmwaremanager-juce547-downloadtask-and-xdg-data-home.patch` | `Source/FirmwareManager.cpp` | Two changes: (a) same `downloadToFile()` raw-pointer fix for the firmware download path; (b) on Linux, store downloaded firmwares in `$XDG_DATA_HOME/FlowtoysFirmwares` (default `~/.local/share/FlowtoysFirmwares`) — JUCE 5.4.7 maps `userApplicationDataDirectory` to `~/.config`, which is for configuration, not data, and it ignores the XDG env vars entirely. A leftover `~/.config/FlowtoysFirmwares` from an earlier build is ignored and can be deleted. |
| `0003-main-hidpi-scale-env.patch` | `Source/Main.cpp` | JUCE 5.4.7 has no automatic HiDPI scaling on Linux; under XWayland on a scaled display the UI renders tiny. Reads `FLOWTOYS_SCALE` (e.g. `2`, `1.5`) and applies `Desktop::setGlobalScaleFactor`. |
| `0004-gui-basics-include-array-modern-gcc.patch` | `JuceLibraryCode/include_juce_gui_basics.cpp` | JUCE 5.4.7's X11 code uses `std::array` without including `<array>`; modern GCC (13+) no longer pulls it in transitively. |
| `0005-makefile-x11-libs-and-o1.patch` | `Builds/LinuxMakefile/Makefile` | Two build fixes. **(a) add `x11 xinerama xext` to every `pkg-config` call** (`--cflags`, `--libs`, `--print-errors`): the v1.1.9 Projucer-generated `LinuxMakefile` only passes `freetype2 libcurl` to pkg-config, so `-lX11 -lXext -lXinerama` never reach the linker → undefined references. This is the fix for the link failure. **(b) `-O3`→`-O1`:** GCC miscompiles JUCE 5.4.7's `juce::URL` copy-assignment (a `ReferenceCountedArray` copy) at `-O2`/`-O3`, producing a null-pointer dereference that crashes the app on launch (100% reproducible; verified on GCC 10 and 16). `-O1` avoids it (`-O0` also works). This is the fix for the startup SIGSEGV. |

## Regenerating

After editing the submodule working tree:

```bash
cd external/FlowtoysUpdater
git diff -- Source/AppUpdater.cpp                       > ../../patches/0001-appupdater-juce547-and-linux-noautoupdate.patch
git diff -- Source/FirmwareManager.cpp                  > ../../patches/0002-firmwaremanager-juce547-downloadtask-and-xdg-data-home.patch
git diff -- Source/Main.cpp                             > ../../patches/0003-main-hidpi-scale-env.patch
git diff -- JuceLibraryCode/include_juce_gui_basics.cpp > ../../patches/0004-gui-basics-include-array-modern-gcc.patch
git diff -- Builds/LinuxMakefile/Makefile              > ../../patches/0005-makefile-x11-libs-and-o1.patch
```

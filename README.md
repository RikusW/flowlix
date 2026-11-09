# Flowlix

Open Source code to interact with flowtoy's capsule 2.

## About 

This rpeo adds Linux support for updating **flowtoys capsule 2.0** (and Vision) props.

## Install

Grab a package from the [releases](https://github.com/jon4hz/flowlix/releases),
or on Arch:

```bash
yay -S flowtoys-updater-bin
```

Packages install the binary, a udev rule (`/usr/lib/udev/rules.d/70-flowtoys.rules`)
for USB access, a `.desktop` entry, and an icon.


You might need to reboot your machine after installing the package, so that the new udev rule becomes active.


## Run

```bash
flowtoys-updater
```

Per flowtoys' own instructions: **have the capsule off/dark and unplugged for
~60 seconds**, pick "Capsule 2.0" in the app, and only then plug it in. It should
appear (and typically glow blue). The app downloads firmware from
`flow-toys.com/fusion/`, so it needs internet on first run.

### HiDPI / Wayland — fonts too small?

JUCE 5.4.7 has no automatic display scaling on Linux, so under XWayland on a
scaled display the UI renders at 1×. Set a scale factor:

```bash
FLOWTOYS_SCALE=2 flowtoys-updater      # try 1.5, 2, 2.5 ...
```

### Auto-update

Disabled on Linux by design: the app still tells you when a newer version
exists, but you install it through your package manager (not an in-app download).

## Repository layout

| Path | What |
|------|------|
| `external/FlowtoysUpdater` | Upstream source, git submodule pinned to a known commit. |
| `patches/`                 | Linux fixes applied to the submodule at build time (see `patches/README.md`). |
| `Dockerfile`               | Hermetic build (only host dep: podman/docker); outputs the binary. |
| `scripts/build-in-docker.sh` | Runs the container build → `prebuilt/linux_amd64/FlowtoysUpdater`. |
| `scripts/build-in-place.sh` | Native in-place build (clones JUCE to `external/JUCE`) → same output. |
| `.goreleaser.yaml`         | GoReleaser Pro config: prebuilt binary → tar.gz + deb + rpm + Arch + AUR. |
| `.github/workflows/`       | `build.yml` (PR sanity build) and `release.yml` (tagged release). |
| `packaging/`               | udev rule + `.desktop` entry shipped in the packages. |


> **Minimum glibc.** The binary is built on Fedora 44, so it needs a current
> distro (recent Fedora/Arch, Debian 13+, Ubuntu 24.04+). Older releases may lack
> a new enough glibc.

## Build locally

Only Docker/Podman is required — no host toolchain or JUCE install:

```bash
./scripts/build-in-docker.sh        # -> prebuilt/linux_amd64/FlowtoysUpdater
```

Or build natively, in place. This needs `git`, a C++ toolchain and the
X11/freetype/libcurl/libusb dev packages; JUCE is cloned into `external/JUCE`
automatically and the patches are applied to the `external/FlowtoysUpdater`
working tree (patches already applied are skipped, so it can be re-run):

```bash
./scripts/build-in-place.sh         # -> prebuilt/linux_amd64/FlowtoysUpdater
```

Cut a release (needs a GoReleaser Pro key, and `AUR_KEY` for AUR publishing):

```bash
GORELEASER_KEY=... goreleaser release --clean          # on a tag
GORELEASER_KEY=... goreleaser release --snapshot --clean --skip=publish   # dry run
```

## Notable Linux fixes (in `patches/`)

- **Startup crash fix**: GCC miscompiles JUCE 5.4.7's `juce::URL` copy at
  `-O2`/`-O3` (null-pointer deref, 100% crash on launch). Release is built at
  `-O1`.
- **HiDPI scaling** via `FLOWTOYS_SCALE`.
- **Auto-update** made informational-only on Linux.
- JUCE 5.4.7 / modern-GCC build fixes (`downloadToFile` API, `<array>` include).

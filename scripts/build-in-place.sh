#!/usr/bin/env bash
#
# Build the FlowtoysUpdater binary natively, in place, without a container.
#
# JUCE is a shallow submodule at external/JUCE (the Makefile references
# ../../../JUCE/modules, which resolves there). The patches in patches/ are
# applied to the external/FlowtoysUpdater submodule working tree; patches that
# are already applied are skipped, so the script is safe to re-run. The Release
# build is staged as a stripped binary in prebuilt/linux_amd64/.
#
set -euo pipefail

cd "$(dirname "$0")/.."

ROOT="$PWD"
APP="external/FlowtoysUpdater"
JUCE="external/JUCE"
BUILD_DIR="$APP/Builds/LinuxMakefile"
OUT_DIR="prebuilt/linux_amd64"

# --- Preconditions -----------------------------------------------------------

if [ ! -f "$BUILD_DIR/Makefile" ]; then
  echo "!! $APP is not initialised; run: git submodule update --init --recursive" >&2
  exit 1
fi

missing_cmds=()
for cmd in git make g++ nproc pkg-config strip; do
  command -v "$cmd" >/dev/null 2>&1 || missing_cmds+=("$cmd")
done
if [ ${#missing_cmds[@]} -gt 0 ]; then
  echo "!! Missing commands: ${missing_cmds[*]}" >&2
  exit 1
fi

missing_pkgs=()
for pkg in x11 xinerama xext freetype2 libcurl libusb-1.0; do
  pkg-config --exists "$pkg" || missing_pkgs+=("$pkg")
done
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  echo "!! Missing pkg-config packages: ${missing_pkgs[*]}" >&2
  echo "   Debian/Ubuntu: sudo apt install libx11-dev libxinerama-dev libxext-dev libfreetype6-dev libcurl4-openssl-dev libusb-1.0-0-dev" >&2
  echo "   Fedora:        sudo dnf install libX11-devel libXinerama-devel libXext-devel freetype-devel libcurl-devel libusb1-devel" >&2
  exit 1
fi

# --- JUCE --------------------------------------------------------------------

# A shallow (depth-1) submodule pinned to the tag the Makefile was generated for.
echo ">> Initialising JUCE submodule"
git submodule update --init --depth 1 -- "$JUCE"

# --- Patches -----------------------------------------------------------------

for p in patches/*.patch; do
  name="$(basename "$p")"
  if git -C "$APP" apply --check "$ROOT/$p" 2>/dev/null; then
    git -C "$APP" apply "$ROOT/$p"
    echo ">> Applied $name"
  elif git -C "$APP" apply -R --check "$ROOT/$p" 2>/dev/null; then
    echo ">> Skipped $name (already applied)"
  else
    echo "!! Cannot apply $name; $APP has conflicting local changes:" >&2
    git -C "$APP" apply --check "$ROOT/$p" || true
    exit 1
  fi
done

# --- Build -------------------------------------------------------------------

echo ">> Building FlowtoysUpdater (Release)"
make -C "$BUILD_DIR" CONFIG=Release clean
make -C "$BUILD_DIR" CONFIG=Release -j"$(nproc)"

# --- Stage -------------------------------------------------------------------

mkdir -p "$OUT_DIR"
install -m 0755 "$BUILD_DIR/build/FlowtoysUpdater" "$OUT_DIR/FlowtoysUpdater"
strip "$OUT_DIR/FlowtoysUpdater"
echo ">> Wrote $OUT_DIR/FlowtoysUpdater"

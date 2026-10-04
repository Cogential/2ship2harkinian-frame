# 2 Ship 2 Harkinian on the Steam Frame

This fork adds a native **aarch64 Linux** build of 2 Ship 2 Harkinian for Valve's Steam Frame
(Snapdragon 8 Gen 3, SteamOS on Arm). Running natively avoids FEX x86 emulation, so the game gets
the full CPU budget of the headset.

The game runs as a flat window on a virtual screen in the headset. Stereoscopic/VR rendering is not
part of this first stage (see [Roadmap](#roadmap)).

> You must supply your own legally obtained Majora's Mask ROM. No ROM or game assets are included
> in this repository or its builds.

## What's different from upstream 2Ship

| Area | Change |
| --- | --- |
| Build | `CMake/toolchains/linux-aarch64.cmake` cross toolchain, `-DSTEAM_FRAME=ON` Snapdragon 8 Gen 3 code generation, `steamframe/build-arm64.sh` |
| Packaging | AppImage packaging picks `linuxdeploy` for the target architecture, so arm64 builds produce an arm64 AppImage |
| CI | `.github/workflows/steam-frame.yml` builds an arm64 AppImage on GitHub's `ubuntu-22.04-arm` runner |
| Runtime | `mm/2s2h/SteamFrame/` detects the Frame at launch and fills in headset-friendly defaults |

### Steam Frame defaults

When the game detects it's running on a Steam Frame (aarch64 + SteamOS), it fills in these defaults
for any setting you haven't already changed. Anything you change later from the menu is kept.

| Setting | Default on Frame | Why |
| --- | --- | --- |
| Controller menu navigation | On | There's no keyboard or mouse in the headset. Press **View** (Back) to open the menu and use the controller to navigate it |
| Allow multi-windows | Off | The game is shown on one virtual screen, so popout windows stay inside it |
| UI scale | 150% | Menu text is easier to read on a virtual screen a few metres away |
| VSync | On | Avoids tearing in the compositor |
| Fullscreen | On, 1920x1080 backbuffer | Without this, libultraship picks the Steam Deck's 1280x800 when it runs under gamescope |

To force detection either way, set the `S2H_STEAM_FRAME` environment variable: `S2H_STEAM_FRAME=1`
applies the defaults on any machine (useful for testing on a desktop), and `S2H_STEAM_FRAME=0`
turns them off on the headset. In Steam, set it in the game's launch options as
`S2H_STEAM_FRAME=0 %command%`.

## Installing on the Frame

1. Download the `2ship-steam-frame-arm64` artifact from the `steam-frame` GitHub Actions workflow,
   or build it yourself (below).
2. Make a folder for the game, e.g. `~/Games/2ship/`, copy `2ship-steam-frame-arm64.appimage` into it
   and make it executable (`chmod +x`).
3. Copy your ROM (`.z64`, NTSC-U 1.0 or NTSC-U GameCube) into the same folder. 2Ship keeps its
   data, saves and `mm.o2r` in the folder it's started from (or in `$SHIP_HOME`, if that's set).
   On first launch it searches that folder for ROMs and offers to extract them, so you don't need
   a file picker in the headset.
4. In Desktop Mode, add the AppImage to Steam with **Add a Non-Steam Game**. Steam sets the
   shortcut's *Start In* directory to the AppImage's folder. Then launch the game from your
   library.

On first launch 2Ship builds `mm.o2r` from the ROM. This takes a while on the headset and only
happens once.

### Personal bundle (skips the first-run ROM step)

`steamframe/make-personal-bundle.sh` builds a ready-to-copy folder on your own PC from the release
AppImage, your ROM and, optionally, an `mm.o2r` you've already made from it. It checks the ROM
against the supported hashes and adds a `2ship.sh` launcher that keeps saves and settings in that
folder. With an `mm.o2r` included, the game skips the first-run ROM step and starts straight away.

```sh
steamframe/make-personal-bundle.sh --rom "Majora's Mask (USA).z64" \
    --appimage 2ship-steam-frame-arm64.appimage --o2r mm.o2r
```

Copy `2ship-frame-bundle/` to the Frame and add `2ship.sh` to Steam as a non-Steam game. The
bundle is your personal copy of the game: keep it on your own devices and never upload it to
GitHub, including as a release asset.

Supported ROMs are listed in [`supportedHashes.json`](supportedHashes.json).

## Building

### Cross-compiling from x86_64 Ubuntu 24.04

Ubuntu serves arm64 packages from `ports.ubuntu.com`, so restrict the default sources to amd64 and
add a ports source for arm64:

```sh
sudo sed -i 's|^Types: deb$|Types: deb\nArchitectures: amd64|' /etc/apt/sources.list.d/ubuntu.sources
sudo tee /etc/apt/sources.list.d/ubuntu-ports-arm64.sources <<'EOF'
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-security
Components: main universe restricted multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```

Then let the script install the packages and build:

```sh
git submodule update --init --recursive
INSTALL_DEPS=1 steamframe/build-arm64.sh
```

A cross build can't run ZAPD (an arm64 binary) to produce `2ship.o2r`. That file doesn't depend on
the architecture, so build it with a normal host build and copy it in:

```sh
cmake -S . -B build -G Ninja && cmake --build build --target Generate2ShipOtr
cp build/mm/2ship.o2r build-steamframe/mm/
```

If `qemu-user` is installed, the toolchain registers it as the cross-compiling emulator, and you
can smoke-test the arm64 binary on the host:
`qemu-aarch64 -L /usr/aarch64-linux-gnu build-steamframe/mm/2s2h.elf`.

### Building natively on Arm64

On an Arm64 Linux machine, such as the Frame in Desktop Mode, the SteamOS/Holo development
container, or an Arm cloud VM:

```sh
INSTALL_DEPS=1 steamframe/build-arm64.sh --native   # Debian/Ubuntu package names
```

On Arch-based systems, install the Arch dependencies from [BUILDING.md](BUILDING.md), then run the
script without `INSTALL_DEPS`.

### Packaging

```sh
(cd build-steamframe && cpack -G External)   # produces an aarch64 .appimage
```

## Graphics notes

The Frame's Adreno 750 GPU is driven by Mesa's Turnip Vulkan driver, and Valve provides OpenGL
through Zink, which runs on top of Turnip. 2Ship's default OpenGL renderer works through that
stack. If you hit performance problems, try these first:

- Leave MSAA at 1 and Internal Resolution at 100%.
- Keep the frame rate at the original 20 FPS, or raise it gradually. The virtual screen is anchored
  in the world, so a low content frame rate doesn't cause discomfort.

## Roadmap

1. **Done in this stage:** native arm64 build, toolchain, CI, Frame detection and defaults.
2. Run and profile it on real hardware, and tune the defaults (backbuffer size, frame
   interpolation, texture filter) using measurements.
3. Apply 2Ship's existing aarch64 tweaks to libultraship (crash handler register dump for arm64).
   This has to go upstream to libultraship, because it lives in a submodule.
4. Package for Steam: a launcher with the Steam Linux Runtime (arm64) and Steam Input default
   bindings for the Frame controllers.
5. Optional VR mode: an OpenXR presentation path with a stereo camera from the game's view matrix,
   head-tracked camera, and the HUD on a quad layer. This is a large project and needs changes in
   libultraship's Fast3D renderer.

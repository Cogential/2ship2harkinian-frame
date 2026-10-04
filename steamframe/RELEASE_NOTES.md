**Test build: native ARM64 Linux build of 2 Ship 2 Harkinian for the Steam Frame.**

### Fixes in frame-v0.1.1
- **Frame detection inside Steam Linux Runtime.** The game read the runtime's `/etc/os-release`
  instead of SteamOS's, so the Frame defaults could silently not apply. It now reads the host's
  `/run/host/os-release` first, and also recognises `VARIANT_ID=vr`.
- **Fullscreen default.** libultraship's `Config::Contains()` reports a missing nested setting as
  present when its parent exists, so the 1920x1080 size was never written, and fullscreen was skipped
  entirely if an older config already had window settings. Both now apply correctly.
- **ROM search crash.** Searching a folder that doesn't exist yet called `closedir(NULL)`.

Tested: the ARM64 build under emulation detects the Frame from a SteamOS `/run/host/os-release`
without `S2H_STEAM_FRAME`. A config with only windowed settings now gets fullscreen at 1920x1080.
Not yet tested on a real Frame.

v0.1.0 was tested by running the ARM64 binary under emulation with the NTSC-U 1.0 ROM: ROM
extraction, boot and the title demo all work.

### Install
1. Make a folder on the Frame, e.g. `~/Games/2ship/`.
2. Put `2ship-steam-frame-arm64.appimage` in it and make it executable (`chmod +x`).
3. Put your own Majora's Mask ROM (`.z64`, NTSC-U 1.0 or NTSC-U GameCube) in the same folder.
   **No ROM or game assets are included.**
4. In Desktop Mode, use **Add a Non-Steam Game** in Steam to add the AppImage, then launch it.
5. On first launch, say **Yes** when it offers to process the ROM it found. This builds `mm.o2r`
   and only happens once.

You can also run it from a terminal in Desktop Mode: `./2ship-steam-frame-arm64.appimage`. If FUSE
isn't available, add `--appimage-extract-and-run`.

### Frame defaults
On the Frame the game turns on controller menu navigation (press **View** to open the menu), 150%
menu text, VSync and 1920x1080 fullscreen, and keeps everything on one screen. Settings you change
are kept. Set `S2H_STEAM_FRAME=0 %command%` in the launch options to turn the defaults off.

### Please report
- Whether it launches, and the frame rate / smoothness you get
- Any graphics glitches (the Frame runs OpenGL through Zink on top of Vulkan)
- Controller behaviour in game and in the menu
- Crash logs: the `logs/` folder next to the AppImage

See `steam-frame.txt` (docs/STEAM_FRAME.md) for details.

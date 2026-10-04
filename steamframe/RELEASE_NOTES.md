**Test build: native ARM64 Linux build of 2 Ship 2 Harkinian for the Steam Frame.**

This build hasn't been tested on a real Steam Frame yet. It was tested by running the ARM64 binary
under emulation with the NTSC-U 1.0 ROM: ROM extraction, boot and the title demo all work.

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

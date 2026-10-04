#ifndef STEAM_FRAME_H
#define STEAM_FRAME_H

// Support for running 2Ship natively on the Steam Frame (Snapdragon 8 Gen 3, aarch64 SteamOS).
//
// The game is shown as a flat window on a virtual screen inside the headset, so the work here is
// about making that experience usable without a keyboard or mouse: controller-driven menus, a
// single fullscreen surface and text that is readable at a distance.
namespace SteamFrame {

// True when running on a Steam Frame. Set S2H_STEAM_FRAME=1 (or 0) to force the answer, e.g. to
// test the Frame defaults on a desktop or to opt out of them on the headset.
bool IsSteamFrame();

// Fills in Frame-friendly defaults for any setting the user has not chosen themselves. Must run
// after the configuration and CVars are loaded and before the window is created.
void ApplyDefaults();

} // namespace SteamFrame

#endif // STEAM_FRAME_H

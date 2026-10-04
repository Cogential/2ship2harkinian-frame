#include "SteamFrame.h"

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>

#include <libultraship/libultraship.h>

namespace SteamFrame {

namespace {

#if defined(__linux__) && defined(__aarch64__)
// SteamOS reports ID=steamos; the Frame's Arch Linux ARM base (Holo) reports ID=holo.
bool IsSteamOS() {
    std::ifstream osRelease("/etc/os-release");
    std::string line;
    while (std::getline(osRelease, line)) {
        if (line.rfind("ID=", 0) != 0) {
            continue;
        }
        std::string id = line.substr(3);
        if (id.size() >= 2 && id.front() == '"' && id.back() == '"') {
            id = id.substr(1, id.size() - 2);
        }
        return id == "steamos" || id == "holo";
    }
    return false;
}
#endif

bool Detect() {
    if (const char* forced = std::getenv("S2H_STEAM_FRAME")) {
        return std::strcmp(forced, "0") != 0;
    }
#if defined(__linux__) && defined(__aarch64__)
    // The Frame is the only aarch64 device SteamOS ships on.
    return IsSteamOS();
#else
    return false;
#endif
}

} // namespace

bool IsSteamFrame() {
    static const bool sIsSteamFrame = Detect();
    return sIsSteamFrame;
}

void ApplyDefaults() {
    if (!IsSteamFrame()) {
        return;
    }

    SPDLOG_INFO("Steam Frame detected, applying Steam Frame defaults");

    // The Frame has no keyboard or mouse in the headset: let the controller's View button open
    // the menu and drive it.
    CVarRegisterInteger(CVAR_IMGUI_CONTROLLER_NAV, 1);
    // The game is presented as a single virtual screen, so keep popout windows inside it.
    CVarRegisterInteger(CVAR_ENABLE_MULTI_VIEWPORTS, 0);
    // Menu text is read from a virtual screen a few metres away; default to the 150% UI scale.
    CVarRegisterInteger("gSettings.ImGuiScale", 2);
    CVarRegisterInteger(CVAR_VSYNC_ENABLED, 1);

    auto config = Ship::Context::GetInstance()->GetConfig();
    if (!config->Contains("Window.Fullscreen.Enabled")) {
        config->SetBool("Window.Fullscreen.Enabled", true);
    }
    // Backbuffer size of the flat window; the compositor scales it onto the virtual screen.
    // libultraship otherwise picks the Steam Deck's 1280x800 under gamescope.
    if (!config->Contains("Window.Fullscreen.Width") && !config->Contains("Window.Fullscreen.Height")) {
        config->SetInt("Window.Fullscreen.Width", 1920);
        config->SetInt("Window.Fullscreen.Height", 1080);
    }
    config->Save();
}

} // namespace SteamFrame

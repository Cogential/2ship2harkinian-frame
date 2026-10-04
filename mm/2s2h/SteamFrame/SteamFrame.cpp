#include "SteamFrame.h"

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>

#include <libultraship/libultraship.h>

namespace SteamFrame {

namespace {

#if defined(__linux__) && defined(__aarch64__)
std::string OsReleaseValue(const std::string& key) {
    // Inside Steam Linux Runtime (pressure-vessel) /etc/os-release describes the runtime; the host's
    // copy is mounted at /run/host/os-release.
    std::ifstream osRelease("/run/host/os-release");
    if (!osRelease.is_open()) {
        osRelease.open("/etc/os-release");
    }
    std::string line;
    while (std::getline(osRelease, line)) {
        if (line.rfind(key + "=", 0) != 0) {
            continue;
        }
        std::string value = line.substr(key.size() + 1);
        if (value.size() >= 2 && value.front() == '"' && value.back() == '"') {
            value = value.substr(1, value.size() - 2);
        }
        return value;
    }
    return "";
}
#endif

bool Detect() {
    if (const char* forced = std::getenv("S2H_STEAM_FRAME")) {
        return std::strcmp(forced, "0") != 0;
    }
#if defined(__linux__) && defined(__aarch64__)
    // The Frame reports ID=steamos, VARIANT_ID=vr. It is the only aarch64 device SteamOS ships on;
    // its Arch Linux ARM base (Holo) reports ID=holo.
    const std::string id = OsReleaseValue("ID");
    return id == "steamos" || id == "holo" || OsReleaseValue("VARIANT_ID") == "vr";
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

    // Config::Contains() can't be used here: for a missing nested key it finds the nearest parent.
    auto config = Ship::Context::GetRawInstance()->GetConfig();
    const bool fullscreenSet =
        config->GetBool("Window.Fullscreen.Enabled", false) == config->GetBool("Window.Fullscreen.Enabled", true);
    if (!fullscreenSet) {
        config->SetBool("Window.Fullscreen.Enabled", true);
    }
    // Backbuffer size of the flat window; the compositor scales it onto the virtual screen.
    // libultraship otherwise picks the Steam Deck's 1280x800 under gamescope.
    if (config->GetInt("Window.Fullscreen.Width", -1) == -1 && config->GetInt("Window.Fullscreen.Height", -1) == -1) {
        config->SetInt("Window.Fullscreen.Width", 1920);
        config->SetInt("Window.Fullscreen.Height", 1080);
    }
    config->Save();
}

} // namespace SteamFrame

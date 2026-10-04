#!/usr/bin/env bash
# Builds 2Ship for the Steam Frame (aarch64 Linux).
#
#   steamframe/build-arm64.sh            # cross-compile from an x86_64 Debian/Ubuntu host
#   steamframe/build-arm64.sh --native   # build on an aarch64 machine (Arm Linux box, Frame dev container)
#
# Set INSTALL_DEPS=1 to have the script install the Ubuntu packages it needs (uses sudo, and for a
# cross build adds the arm64 architecture to apt). Output ends up in build-steamframe/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build-steamframe}"
NATIVE=0
[[ "${1:-}" == "--native" ]] && NATIVE=1

DEV_PKGS="libusb-1.0-0-dev libsdl2-dev libsdl2-net-dev libpng-dev libglew-dev libtinyxml2-dev libspdlog-dev
          libogg-dev libopus-dev libopusfile-dev libvorbis-dev libzip-dev libopengl-dev libbz2-dev zlib1g-dev"

if [[ "${INSTALL_DEPS:-0}" == "1" ]]; then
    if [[ $NATIVE == 1 ]]; then
        sudo apt-get update
        sudo apt-get install -y gcc g++ git cmake ninja-build python3 lsb-release nlohmann-json3-dev zipcmp zipmerge ziptool $DEV_PKGS
    else
        # Ubuntu serves arm64 from ports.ubuntu.com; pin the existing sources to amd64 first.
        echo "Configure apt for arm64 multiarch (see docs/STEAM_FRAME.md) before using INSTALL_DEPS=1 for a cross build."
        sudo dpkg --add-architecture arm64
        sudo apt-get update
        sudo apt-get install -y crossbuild-essential-arm64 git cmake ninja-build python3 lsb-release nlohmann-json3-dev \
            $(for p in $DEV_PKGS; do printf '%s:arm64 ' "$p"; done)
    fi
fi

CMAKE_ARGS=(-S "$ROOT" -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release -DSTEAM_FRAME=ON)
if [[ $NATIVE == 0 ]]; then
    CMAKE_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="$ROOT/CMake/toolchains/linux-aarch64.cmake")
fi

cmake "${CMAKE_ARGS[@]}"

if [[ $NATIVE == 1 ]]; then
    cmake --build "$BUILD_DIR" --target Generate2ShipOtr
elif [[ ! -f "$BUILD_DIR/mm/2ship.o2r" ]]; then
    # 2ship.o2r is architecture independent but is produced by running ZAPD, which a cross build
    # makes for aarch64. Build it with any host (x86_64) build and copy it over.
    echo "note: copy a 2ship.o2r from a host build into $BUILD_DIR/mm/ (e.g. cmake --build build --target Generate2ShipOtr)"
fi

cmake --build "$BUILD_DIR"
echo "Built $BUILD_DIR/mm/2s2h.elf"

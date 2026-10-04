# Cross-compile toolchain for 64-bit ARM Linux (aarch64), e.g. the Steam Frame.
#
# Assumes a Debian/Ubuntu multiarch host with the aarch64 cross compilers and the :arm64
# development packages installed (see steamframe/build-arm64.sh). Override the compiler prefix
# with -DAARCH64_TRIPLE=... if your toolchain uses a different one.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

if(NOT DEFINED AARCH64_TRIPLE)
    set(AARCH64_TRIPLE aarch64-linux-gnu)
endif()

find_program(AARCH64_CC NAMES ${AARCH64_TRIPLE}-gcc-14 ${AARCH64_TRIPLE}-gcc-13 ${AARCH64_TRIPLE}-gcc-12 ${AARCH64_TRIPLE}-gcc REQUIRED)
find_program(AARCH64_CXX NAMES ${AARCH64_TRIPLE}-g++-14 ${AARCH64_TRIPLE}-g++-13 ${AARCH64_TRIPLE}-g++-12 ${AARCH64_TRIPLE}-g++ REQUIRED)
set(CMAKE_C_COMPILER ${AARCH64_CC})
set(CMAKE_CXX_COMPILER ${AARCH64_CXX})

# Multiarch layout: target libraries live in /usr/lib/aarch64-linux-gnu and share /usr/include.
set(CMAKE_LIBRARY_ARCHITECTURE ${AARCH64_TRIPLE})
set(CMAKE_FIND_ROOT_PATH /usr/${AARCH64_TRIPLE})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/${AARCH64_TRIPLE}/pkgconfig:/usr/share/pkgconfig")
set(ENV{PKG_CONFIG_PATH} "")

# Lets build steps that must run a target binary go through qemu-user when it is installed.
find_program(QEMU_AARCH64 NAMES qemu-aarch64-static qemu-aarch64)
if(QEMU_AARCH64)
    set(CMAKE_CROSSCOMPILING_EMULATOR ${QEMU_AARCH64} -L /usr/${AARCH64_TRIPLE})
endif()

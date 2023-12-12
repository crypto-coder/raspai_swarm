#!/bin/bash

# Based on instructions located here
# https://boyie-chen.medium.com/install-and-run-gpt4all-on-raspberry-pi-4-08af16d7df38

# MAKE SURE EVERYTHING IS UPDATED BEFORE YOU START
if [ "$USER" = "root" ]; then
    apt-get upgrade -y
else
    sudo apt-get upgrade -y
fi

# Move to the working directory
if [ "$HOME" = "" ]; then
    mkdir -p /aiagent
    cd /aiagent
else
    mkdir -p $HOME/dev/aiagent
    cd $HOME/dev/aiagent
fi

# Make sure we have a clone of the GPT4All repo in a predictable place
if [ ! -d "./gpt4all" ]; then
    git clone --recurse-submodules https://github.com/nomic-ai/gpt4all.git gpt4all
fi

# Install Vulkan SDK
if [ "$USER" != "root" ]; then
    sudo apt-get install libxcb-randr0-dev libxrandr-dev -y
    sudo apt-get install libxcb-xinerama0-dev libxinerama-dev libxcursor-dev -y
    sudo apt-get install libxcb-cursor-dev libxkbcommon-dev xutils-dev -y
    sudo apt-get install xutils-dev libpthread-stubs0-dev libpciaccess-dev -y
    sudo apt-get install libffi-dev x11proto-xext-dev libxcb1-dev libxcb-*dev -y
    sudo apt-get install libssl-dev libgnutls28-dev x11proto-dri2-dev -y
    sudo apt-get install x11proto-dri3-dev libx11-dev libxcb-glx0-dev -y
    sudo apt-get install libx11-xcb-dev libxext-dev libxdamage-dev libxfixes-dev -y
    sudo apt-get install libva-dev x11proto-randr-dev x11proto-present-dev -y
    sudo apt-get install libclc-dev libelf-dev mesa-utils -y
    sudo apt-get install libvulkan-dev libvulkan1 libassimp-dev -y
    sudo apt-get install libdrm-dev libxshmfence-dev libxxf86vm-dev libunwind-dev -y
    sudo apt-get install libwayland-dev wayland-protocols -y
    sudo apt-get install libwayland-egl-backend-dev -y
    sudo apt-get install valgrind libzstd-dev vulkan-tools -y
    sudo apt-get install git build-essential bison flex ninja-build -y
    sudo apt-get install python3-mako  -y
    sudo apt-get install python3-pip -y
    sudo apt-get install python3-pkgconfig -y
    sudo apt-get install cmake -y
else
    apt-get install libxcb-randr0-dev libxrandr-dev -y
    apt-get install libxcb-xinerama0-dev libxinerama-dev libxcursor-dev -y
    apt-get install libxcb-cursor-dev libxkbcommon-dev xutils-dev -y
    apt-get install xutils-dev libpthread-stubs0-dev libpciaccess-dev -y
    apt-get install libffi-dev x11proto-xext-dev libxcb1-dev libxcb-*dev -y
    apt-get install libssl-dev libgnutls28-dev x11proto-dri2-dev -y
    apt-get install x11proto-dri3-dev libx11-dev libxcb-glx0-dev -y  # cannot locate x11proto-dri3-dev
    apt-get install libx11-xcb-dev libxext-dev libxdamage-dev libxfixes-dev -y
    apt-get install libva-dev x11proto-randr-dev x11proto-present-dev -y
    apt-get install libclc-dev libelf-dev mesa-utils -y
    apt-get install libvulkan-dev libvulkan1 libassimp-dev -y
    apt-get install libdrm-dev libxshmfence-dev libxxf86vm-dev libunwind-dev -y
    apt-get install libwayland-dev wayland-protocols -y
    apt-get install libwayland-egl-backend-dev -y
    apt-get install valgrind libzstd-dev vulkan-tools -y
    apt-get install git build-essential bison flex ninja-build -y
    apt-get install python3-mako  -y
    apt-get install python3-pip -y
    apt-get install python3-pkgconfig -y
    apt-get install cmake -y
fi
#sudo apt-get install libxcb-glx0-dev libx11-xcb-dev libxcb-dri2-0-dev -y
#sudo apt-get install libxcb-dri3-dev libxcb-present-dev -y

# Build Vulkan API (+meson, +mako)
if [ "$USER" != "root" ]; then
    sudo pip3 install meson
    sudo pip3 install mako
else
    pip3 install meson
    pip3 install mako
fi

git clone -b 20.3 https://gitlab.freedesktop.org/mesa/mesa.git mesa_vulkan
cd mesa_vulkan

CFLAGS="-mcpu=cortex-a72" \
CXXFLAGS="-mcpu=cortex-a72" \
meson --prefix /usr \
-D platforms=x11 \
-D vulkan-drivers=broadcom \
-D dri-drivers= \
-D gallium-drivers=kmsro,v3d,vc4 \
-D buildtype=release build

ninja -C build -j4

if [ "$USER" != "root" ]; then
    sudo ninja -C build install
else
    ninja -C build install
fi

# Build the backend
cd ../gpt4all/gpt4all-backend/
sed -i 's@set(LLAMA_KOMPUTE YES)@#set(LLAMA_KOMPUTE YES)@' CMakeLists.txt 
mkdir build
cd build
cmake .. -DKOMPUTE_OPT_DISABLE_VULKAN_VERSION_CHECK=ON 
cmake --build . --parallel 
# Make sure libllmodel.* exists in gpt4all-backend/build

# Setup Python bindings
cd ../../gpt4all-bindings/python
pip3 install -e .
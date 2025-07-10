<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/wildminder/rexuiz-neo">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

<h1 align="center">Rexuiz Neo Build System</h1>

  <p align="center">
    A modern, cross-platform build system for the game Rexuiz.
    <br />
    <a href="https://github.com/wildminder/rexuiz-neo/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/wildminder/rexuiz-neo/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<!-- PROJECT SHIELDS -->
<div align="center">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#project-structure">Project Structure</a></li>
    <li>
      <a href="#building-the-project">Building the Project</a>
      <ul>
        <li><a href="#prerequisites-for-windows">Prerequisites for Windows</a></li>
        <li><a href="#prerequisites-for-linux-debianubuntu">Prerequisites for Linux (Debian/Ubuntu)</a></li>
        <li><a href="#cloning-and-building">Cloning and Building</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#advanced-build-options">Advanced Build Options</a></li>
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>


<!-- ABOUT THE PROJECT -->
## About The Project

This repository provides a clean, modern, and cross-platform build environment for **Rexuiz**, a fast-paced arena FPS based on the original Nexuiz Classic. This project is not the game itself, but rather the complete toolchain and set of scripts required to build the game engine, launcher, and all associated data from source.

The build system has been heavily refactored to:
*   Maintain a clean and logical directory structure.
*   Isolate all build artifacts from the source code.
*   Support standalone and integrated builds of its components.
*   Provide a streamlined build process on Windows, Linux, and macOS.

**Technical Notes:**
*   Updated all dependencies
*   Resolved compilation issues
*   Compiles flawlessly with `SDL2-2.26.5`.
*   Also compiles with the latest SDL2-2.32.8, but starting from SDL 2.27, there are some issues with loading speed and freezes in the game menu — likely caused by the modern Windows API for gamepad/joystick input (Windows.Gaming.Input).

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- PROJECT STRUCTURE -->
## Project Structure

The project has been reorganized to provide a clean separation between source code, assets, platform-specific files, and generated build artifacts.

```
.
├── Makefile              # The main, top-level build file.
|
├── assets/               # Source game data (models, maps, textures).
|   ├── rexdlc/           # Source for DLC content packs.
|   └── ...
|
├── components/           # Source code for the game engine, tools, and game logic.
|   ├── DarkPlacesRM/     # The game engine.
|   ├── gmqcc/            # The QuakeC compiler.
|   └── ...
|
├── platforms/            # Platform-specific project files (e.g., for Android).
|
├── scripts/              # scripts
|
├── _source/              # [Generated] Cached source archives (.tar.gz) of dependencies.
├── _build/               # [Generated] Intermediate build files. Can be safely deleted.
├── _deps/                # [Generated] Compiled third-party libraries (SDL2, etc.).
└── _dist/                # [Generated] The final, packaged game application.
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Building the Project

### Prerequisites for Windows

You will need to set up the **MSYS2** environment to get the necessary toolchain and libraries.

1.  **Download and Install MSYS2**
    *   Go to the [MSYS2 official website](https://www.msys2.org/) and download the `msys2-x86_64-*.exe` installer.
    *   Run the installer. It's recommended to use a simple path like `C:\msys64`.
    *   After installation, run "MSYS2 MSYS" from your Start Menu.


2.  **Update MSYS2 Core Packages**
    *   In the "MSYS2 MSYS" terminal, update the package database and core packages. You may need to do this multiple times.
        ```bash
        pacman -Syu
        ```
    *   If prompted to close the terminal, do so, then re-open "MSYS2 MSYS" and run the command again until it reports no more updates.


3.  **Install MinGW-w64 Toolchain and Build Tools**
    *   Open the **"MSYS2 MinGW 64-bit"** terminal from your Start Menu.
    *   Install the required toolchain and developer tools:
        ```bash
        pacman -S --needed base-devel mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake mingw-w64-x86_64-wget \
            mingw-w64-x86_64-libzip \
            patch \
            zip \
            unzip \
            p7zip \
            mingw-w64-x86_64-imagemagick \
            mingw-w64-x86_64-libvorbis \
            mingw-w64-x86_64-yasm \
            mingw-w64-x86_64-autotools \
            mingw-w64-x86_64-openssl \
            vim
        ```
    *   Press `Enter` to select all default packages and `Y` to confirm the installation.


4.  **Compile `vorbis-tools` from source (if needed)**
    *   First, check if `oggenc` is available:
        ```bash
        which oggenc
        ```
    *   If not found, clone and compile it from source within the "MSYS2 MinGW 64-bit" terminal:
        ```bash
        git clone https://github.com/xiph/vorbis-tools
        cd vorbis-tools
        AUTOMAKE_FLAGS=--include-deps ./autogen.sh
        ./configure --prefix=/mingw64 
        make
        make install
        cd ..
        ```
    *   Verify the installation again with `which oggenc`.
  
> [!NOTE]
> If you're experiencing trouble compiling Vorbis-Tool on Windows from the official repo, use this repo instead https://github.com/wildminder/vorbis-tools

### Prerequisites for Linux (Debian/Ubuntu)
Open a terminal and install the required build tools and libraries.
```bash
sudo apt update
sudo apt install build-essential git wget patch zip unzip p7zip cmake pkg-config autoconf
```

### Cloning and Building

With the environment set up, you can now clone and build the project.

1.  **Get Game Data**
    *   The build script will attempt to download `nexuiz-252.zip`. If this fails, please download it manually from [SourceForge](https://sourceforge.net/projects/nexuiz/files/) and place it in the `_source` directory.


2.  **Clone the Repository**
    *   Clone the project and its submodules. Make sure you are in the **"MSYS2 MinGW 64-bit"** terminal.
       ```sh
       git clone --recurse-submodules -j8 https://github.com/wildminder/rexuiz-neo.git rexuiz-source
       cd rexuiz-source
       ```

3.  **Build the Project**
    *   Execute the make command. This will download dependencies, compile tools, and build the entire game. Be patient, as this can take a long time.
       ```sh
       # For a 64-bit Windows build
       make DPTARGET=win64

       # For a 64-bit Linux build (DPTARGET is auto-detected)
       make
       ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

*   After a successful build, the complete, playable game will be located in the **`_dist/Rexuiz/`** directory.
*   **On Windows:** The main executable is `_dist/Rexuiz/rexuiz-sdl-x86_64.exe`. All required DLLs for external libraries (like `libfreetype`) are located in `_dist/Rexuiz/bin64/` and are found automatically.
*   **On Linux:** The main executable is `_dist/Rexuiz/rexuiz-linux-sdl-x86_64`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ADVANCED BUILDING -->
## Advanced Build Options

The Makefile is designed to be modular. You can build individual components if needed.

| Target | Description | Command Example |
| :--- | :--- | :--- |
| `all` or `stand-alone` | (Default) Builds the entire project and packages it into `_dist/Rexuiz`. | `make` |
| `engine` | Compiles only the game engine (`DarkPlacesRM`). The output binaries will be in `components/DarkPlacesRM/`. | `make engine` |
| `flrexuizlauncher` | Compiles only the optional FLTK-based game launcher. | `make flrexuizlauncher` |
| `gmqcc` | Compiles only the `gmqcc` QuakeC compiler tool. | `make gmqcc` |
| `update-qc` | Re-compiles the QuakeC game logic files (`progs.dat`, `csprogs.dat`). | `make update-qc` |

### Cross-Compiling

You can cross-compile for other platforms by setting the `CROSSPREFIX` variable. For example, to build the 32-bit Windows version from a Linux machine:
```bash
make DPTARGET=win32 CROSSPREFIX=i686-w64-mingw32-
```


### Building Only the Game Engine (DarkPlacesRM)

If you only want to recompile the game engine without rebuilding the entire project:

1.  Navigate to the root `rexuiz-neo` directory in your "MSYS2 MinGW 64-bit" terminal.
2.  Run the make with `engine`:
    ```bash    
    make engine DPTARGET=win64
    ```
3.  The newly compiled `rexuiz-sdl-x86_64.exe` will be located in the `DarkPlacesRM/` directory. You can copy this executable to your existing game distribution to update it.

### Building the Launcher (Optional)

The project includes an FLTK-based launcher that can be built separately.

*   **For Linux/macOS:**
    ```bash
    make flrexuizlauncher
    ```
*   **For Windows (from MSYS2/MinGW):**
    ```bash
    make flrexuizlauncher DPTARGET=win64
    ```
The compiled launcher will be placed in the `Rexuiz/` directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Troubleshooting

*   **Build Fails on a Specific Library:** If a dependency fails to build, you can try cleaning just that library's build files. For example, if `libvpx` fails: `rm -rf _build/libvpx-1.15.1`. Then re-run `make`.

*   **Cleaning the Build:**
    *   To remove intermediate build files but keep downloaded sources and compiled dependencies:
        ```bash
        make clean
        ```
    *   To perform a deep clean that removes everything except downloaded source archives:
        ```bash
        make distclean
        ```
    *   To start from a completely clean slate, including removing cached downloads:
        ```bash
        make distclean && rm -rf _source
        ```

*   **CMakeCache.txt is different than the directory:**
    This error occurs when CMake's cache points to old paths. To fix it, navigate to the `gmqcc` subdirectory and clean the CMake files before rebuilding.
    ```bash
    cd gmqcc
    rm -f CMakeCache.txt
    rm -rf CMakeFiles/ Makefile cmake_install.cmake
    cd ..
    make DPTARGET=win64
    ```

*   **Disk Space:**
    Ensure you have at least 10-15 GB of free disk space for the toolchain, project sources, dependencies, and compiled binaries.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

*   This build system is a modernization of the original work by **[kasymovga](https://github.com/kasymovga/rexuiz)**.
*   Uses assets from the original **Nexuiz Classic** game.
*   Built with the awesome **DarkPlaces** engine.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/wildminder/rexuiz-neo.svg?style=flat
[contributors-url]: https://github.com/wildminder/rexuiz-neo/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/wildminder/rexuiz-neo.svg?style=flat
[forks-url]: https://github.com/wildminder/rexuiz-neo/network/members
[stars-shield]: https://img.shields.io/github/stars/wildminder/rexuiz-neo.svg?style=flat
[stars-url]: https://github.com/wildminder/rexuiz-neo/stargazers
[issues-shield]: https://img.shields.io/github/issues/wildminder/rexuiz-neo.svg?style=flat
[issues-url]: https://github.com/wildminder/rexuiz-neo/issues

<!-- [license-shield]: https://img.shields.io/github/license/wildminder/rexuiz-neo.svg?style=flat -->
<!-- [license-url]: https://github.com/wildminder/rexuiz-neo/blob/master/LICENSE.txt -->

# =========================================================================
#   Rexuiz Build System - Final Refactored Version
# =========================================================================
#
# This Makefile uses a structured layout to keep the root directory clean.
#
# PROJECT STRUCTURE:
# ./assets/               - Source game data and assets (rexdlc, rexuiz.pk3, etc.)
# ./components/           - Source code for engine, launcher, etc. (DarkPlacesRM, gmqcc, etc.)
# ./platforms/            - Android Studio project files
# ./scripts/              - Utility scripts (run scripts, etc.)
#
# GENERATED DIRECTORIES:
# ./_source/              - (Cache) Downloaded source archives. Can be kept between builds.
# ./_build/               - (Temp) Extracted sources & intermediate files. Deleted by 'make clean'.
# ./_deps/                - (Output) Compiled third-party libraries. Deleted by 'make distclean'.
# ./_dist/                - (Final) The final packaged application. Deleted by 'make clean'.
#

.PHONY: all clean distclean help \
	engine curl freetype \
	stand-alone stand-alone-data stand-alone-engine \
	update-qc gmqcc flrexuizlauncher

# Define an executable extension for the current platform
EXE_EXT :=
ifeq ($(findstring win,$(DPTARGET)),win)
	EXE_EXT := .exe
endif


# =========================================================================
#   Directory & Path Configuration
# =========================================================================
ROOT_DIR  := $(shell pwd)
SRC_DIR   := $(ROOT_DIR)/_source
BUILD_DIR := $(ROOT_DIR)/_build
DEPS_DIR  := $(ROOT_DIR)/_deps
DIST_DIR  := $(ROOT_DIR)/_dist

# Source component paths
DPDIR := components/DarkPlacesRM

# Ensure generated directories exist
$(shell mkdir -p $(SRC_DIR) $(BUILD_DIR) $(DEPS_DIR) $(DIST_DIR))

# =========================================================================
#   Toolchain and Platform Detection
# =========================================================================
STATIC_CLIB=-static-libgcc
STATIC_CXXLIB=-static-libstdc++

# Cross-compilation setup
ifneq ($(CROSSPREFIX),)
	CC      := $(CROSSPREFIX)-gcc
	CXX     := $(CROSSPREFIX)-g++
	AR      := $(CROSSPREFIX)-ar
	RANLIB  := $(CROSSPREFIX)-ranlib
	STRIP   := $(CROSSPREFIX)-strip
	WINDRES := $(CROSSPREFIX)-windres
else
	CC      := gcc
	CXX     := g++
	AR      := ar
	RANLIB  := ranlib
	STRIP   := strip
	WINDRES := windres
endif
LD         := $(CC)
CROSSCMAKE := cmake

# Auto-detect target platform (DPTARGET)
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
	ifeq ($(UNAME_M),x86_64)
		DPTARGET := linux64
	else ifeq ($(UNAME_M),aarch64)
		DPTARGET := linux-arm64
	else ifeq ($(UNAME_M),armv7l)
		DPTARGET := linux-arm32
	else
		DPTARGET := linux32
	endif
else ifeq ($(UNAME_S),Darwin)
	ifeq ($(UNAME_M),x86_64)
		DPTARGET := mac64
	else ifeq ($(UNAME_M),arm64)
		DPTARGET := mac-arm64
	else
		DPTARGET := mac32
	endif
else # Default to Windows
	ifeq ($(UNAME_M),x86_64)
		DPTARGET := win64
	else
		DPTARGET := win32
	endif
endif

# Library Paths (Based on DEPS_DIR)
ifeq ($(DPTARGET),android)
	LIBDIR := $(DEPS_DIR)/$(DPTARGET)/$(ANDROID_ARCH)
else
	LIBDIR := $(DEPS_DIR)/$(DPTARGET)
endif
LIBDIR_FLRL := $(DEPS_DIR)/flrl/$(DPTARGET)

# =========================================================================
#   Dependency Versions & File Definitions
# =========================================================================
LIBSAMPLERATEVERSION := 0.2.2
LIBSAMPLERATEDIR     := libsamplerate-$(LIBSAMPLERATEVERSION)
LIBSAMPLERATETARXZ   := $(LIBSAMPLERATEDIR).tar.xz
LIBSAMPLERATEFILES   := $(LIBDIR)/lib/libsamplerate.a

LIBPNGVERSION     := 1.6.48
LIBPNGDIR         := libpng-$(LIBPNGVERSION)
LIBPNGTARGZ       := $(LIBPNGDIR).tar.gz
LIBPNGFILES       := $(LIBDIR)/lib/libpng.a
LIBPNGFILES_FLRL  := $(LIBDIR_FLRL)/lib/libpng.a

ZLIBDIR        := zlib-1.3.1
ZLIBTARGZ      := $(ZLIBDIR).tar.gz
ZLIBFILES      := $(LIBDIR)/lib/libz.a
ZLIBFILES_FLRL := $(LIBDIR_FLRL)/lib/libz.a

JPEGVERSION := 9f
JPEGDIR     := jpeg-$(JPEGVERSION)
JPEGTARGZ   := jpegsrc.v$(JPEGVERSION).tar.gz
JPEGFILES   := $(LIBDIR)/lib/libjpeg.a
JPEGFILES_FLRL := $(LIBDIR_FLRL)/lib/libjpeg.a

ASSIMPVERSION := 6.0.1
ASSIMPDIR     := assimp-$(ASSIMPVERSION)
ASSIMPTARGZ   := $(ASSIMPDIR).tar.gz

ifeq ($(DPTARGET),android)
	SDLDIR := SDL2-2.0.16
else
	SDLDIR := SDL2-2.26.5
endif
SDLTARGZ := $(SDLDIR).tar.gz

ifeq ($(DPTARGET),android)
	HIDAPIFILES := $(LIBDIR)/lib/libhidapi.so
	SDLFILES    := $(LIBDIR)/lib/libSDL2.so
else
	SDLFILES    := $(LIBDIR)/bin/sdl2-config
endif
SDLFILES_FORDP := $(SDLFILES)

LIBMICROHTTPDVERSION := 1.0.1
LIBMICROHTTPDDIR     := libmicrohttpd-$(LIBMICROHTTPDVERSION)
LIBMICROHTTPDTARGZ   := $(LIBMICROHTTPDDIR).tar.gz
LIBMICROHTTPDFILES   := $(LIBDIR)/lib/libmicrohttpd.a

FREETYPEVERSION := 2.13.3
FREETYPEDIR     := freetype-$(FREETYPEVERSION)
FREETYPETARGZ   := $(FREETYPEDIR).tar.gz

CURLVERSION := 8.14.0
CURLDIR     := curl-$(CURLVERSION)
CURLTARGZ   := $(CURLDIR).tar.gz

LIBOGGVERSION := 1.3.5
LIBOGGDIR     := libogg-$(LIBOGGVERSION)
LIBOGGTARGZ   := $(LIBOGGDIR).tar.gz
LIBOGGFILES   := $(LIBDIR)/lib/libogg.a

LIBVORBISVERSION := 1.3.7
LIBVORBISDIR     := libvorbis-$(LIBVORBISVERSION)
LIBVORBISTARGZ   := $(LIBVORBISDIR).tar.gz
LIBVORBISFILES   := $(LIBDIR)/lib/libvorbis.a $(LIBDIR)/lib/libvorbisenc.a $(LIBDIR)/lib/libvorbisfile.a

LIBTHEORAVERSION := 1.2.0
LIBTHEORADIR     := libtheora-$(LIBTHEORAVERSION)
LIBTHEORATARGZ   := $(LIBTHEORADIR).tar.gz
LIBTHEORAFILES   := $(LIBDIR)/lib/libtheora.a $(LIBDIR)/lib/libtheoraenc.a

MBEDTLSVERSION := 3.6.3.1
MBEDTLSDIR     := mbedtls-$(MBEDTLSVERSION)
MBEDTLSTARGZ   := $(MBEDTLSDIR).tar.gz
MBEDTLSFILES_FLRL := $(LIBDIR_FLRL)/lib/libmbedtls.a

FLTKVERSION := 1.4.3
FLTKDIR     := fltk-release-$(FLTKVERSION)
FLTKTARGZ   := $(FLTKDIR)-sources.tar.gz
FLTKFILES_FLRL := $(LIBDIR_FLRL)/lib/libfltk.a

LIBVPXVERSION := 1.15.1
LIBVPXDIR     := libvpx-$(LIBVPXVERSION)
LIBVPXTARGZ   := v$(LIBVPXVERSION).tar.gz # LibVPX uses a 'v' prefix in its tags
LIBVPXFILES   := $(LIBDIR)/lib/libvpx.a

OPUSVERSION := 1.5.2
OPUSDIR     := opus-$(OPUSVERSION)
OPUSTARGZ   := $(OPUSDIR).tar.gz
OPUSFILES   := $(LIBDIR)/lib/libopus.a

# Helper for flrexuizlauncher dependencies
CURLFILES_FLRL := $(LIBDIR_FLRL)/lib/libcurl.a

# =========================================================================
#   Build Configuration & Flags
# =========================================================================
DPMAKEOPTS_BASE := \
	CC='$(CC) -I$(LIBDIR)/include/SDL2 -I$(LIBDIR)/include -L$(LIBDIR)/lib' \
	LD='$(LD) -L$(LIBDIR)/lib' \
	STRIP=$(STRIP) \
	SDL_CONFIG='$(LIBDIR)/bin/sdl2-config' \
	DP_LIBMICROHTTPD=static \
	DP_LINK_OGGVORBIS=static \
	DP_LINK_ZLIB=static \
	DP_LINK_JPEG=static \
	DP_LINK_PNG=static \
	DP_LINK_OPUS=static \
	WINDRES=$(WINDRES) \
	$(DPMAKEOPTS_EXTRA)

DPMAKEOPTS := $(DPMAKEOPTS_BASE)

# Platform-specific options
ifeq ($(DPTARGET),android)
	DPMAKEOPTS += DP_SDL_STATIC=yes
	DPMAKEOPTS += DP_FS_BASEDIR=/sdcard/Rexuiz/ DP_MAKE_TARGET=android DP_VIDEO_CAPTURE=disabled
	EXTRALIBS_LINKONLY := $(LIBOGGFILES) $(LIBVORBISFILES)
	SDLDEPS :=
else
	DPMAKEOPTS += DP_LINK_VPX=static
	EXTRALIBS_LINKONLY := $(LIBOGGFILES) $(LIBVORBISFILES) $(LIBTHEORAFILES) $(LIBVPXFILES)
	SDLDEPS := $(LIBSAMPLERATEFILES)
endif

ifeq ($(DPTARGET),linux32)
	ARCHSUFFIX      := i686
	DPTARGET_LINUX  := y
	DPMAKEOPTS      += DP_MAKE_TARGET=linux
endif
ifeq ($(DPTARGET),linux64)
	ARCHSUFFIX      := x86_64
	DPTARGET_LINUX  := y
	DPMAKEOPTS      += DP_MAKE_TARGET=linux
endif
ifeq ($(DPTARGET),linux-arm64)
	ARCHSUFFIX      := aarch64
	DPTARGET_LINUX  := y
	DPMAKEOPTS      += DP_MAKE_TARGET=linux DP_SSE=0
endif
ifeq ($(DPTARGET),linux-arm32)
	ARCHSUFFIX      := armv7l
	DPTARGET_LINUX  := y
	DPMAKEOPTS      += DP_MAKE_TARGET=linux DP_SSE=0
endif

ifeq ($(DPTARGET),win32)
	DPTARGET_WIN := y
	ARCHSUFFIX   := i686
	DPMAKEOPTS   += DP_MAKE_TARGET=mingw TARGET=$(CROSSPREFIX) LIB_LIBMICROHTTPD='-lmicrohttpd -lws2_32' OBJ_ICON=rexuiz.o
endif
ifeq ($(DPTARGET),win64)
	DPTARGET_WIN := y
	ARCHSUFFIX   := x86_64
	DPMAKEOPTS   += DP_MAKE_TARGET=mingw TARGET=$(CROSSPREFIX) MINGWARCH=x86_64 LIB_LIBMICROHTTPD='-lmicrohttpd -lws2_32' OBJ_ICON=rexuiz.o
endif

ifeq ($(DPTARGET),mac32)
	DPTARGET_MAC := y
	ARCHSUFFIX   := i686
	APPNAME      := Rexuiz-i386.app
	DPMAKEOPTS   += DP_MAKE_TARGET=macosx
endif
ifeq ($(DPTARGET),mac64)
	DPTARGET_MAC := y
	ARCHSUFFIX   := x86_64
	APPNAME      := Rexuiz.app
	DPMAKEOPTS   += DP_MAKE_TARGET=macosx
endif
ifeq ($(DPTARGET),mac-arm64)
	DPTARGET_MAC := y
	ARCHSUFFIX   := arm64
	APPNAME      := Rexuiz-arm64.app
	DPMAKEOPTS   += DP_MAKE_TARGET=macosx DP_SSE=0
endif

# Define EXTRALIBS based on platform
ifeq ($(DPTARGET_WIN),y)
	FREETYPEFILES := $(LIBDIR)/bin/libfreetype-6.dll
	CURLFILES     := $(LIBDIR)/bin/libcurl-4.dll
	ifeq ($(ASSIMP_ENABLE),y)
		ASSIMPFILES := $(LIBDIR)/bin/libassimp-5.dll
	endif
else ifeq ($(DPTARGET_MAC),y)
	FREETYPEFILES := $(LIBDIR)/lib/libfreetype.dylib
	CURLFILES     := $(LIBDIR)/lib/libcurl.dylib
	ifeq ($(ASSIMP_ENABLE),y)
		ASSIMPFILES := $(LIBDIR)/lib/libassimp.dylib
	endif
else ifeq ($(DPTARGET),android)
	FREETYPEFILES := $(LIBDIR)/lib/libfreetype.so
	CURLFILES     := $(LIBDIR)/lib/libcurl.so
else # Linux
	DPMAKEOPTS    += DP_FS_BASEDIR=/usr/share/rexuiz/
	FREETYPEFILES := $(LIBDIR)/lib/libfreetype.so
	CURLFILES     := $(LIBDIR)/lib/libcurl.so
	ifeq ($(ASSIMP_ENABLE),y)
		ASSIMPFILES := $(LIBDIR)/lib/libassimp.so
	endif
endif
EXTRALIBS := $(FREETYPEFILES) $(CURLFILES) $(ASSIMPFILES)


# =========================================================================
#   Main Targets
# =========================================================================

# The default target: build the stand-alone game.
all: stand-alone

# A help target to explain how to use the Makefile.
help:
	@echo "Rexuiz Build System"
	@echo ""
	@echo "Common Commands:"
	@echo "  make all              - Build the complete stand-alone application."
	@echo "  make stand-alone      - Alias for 'all'."
	@echo "  make clean            - Remove intermediate build files (_build, _dist)."
	@echo "  make distclean        - Remove all generated files including compiled deps (_build, _dist, _deps)."
	@echo "  make help             - Show this help message."
	@echo ""
	@echo "To start from a completely clean slate (including cached downloads):"
	@echo "  make distclean && rm -rf _source"
	@echo ""

# Clean removes temporary files, but keeps compiled dependencies for faster rebuilds.
clean:
	@echo "Cleaning up temporary build files and distribution directory..."
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	cd $(DPDIR) && $(MAKE) clean || true
	cd components/flrexuizlauncher && $(MAKE) clean || true
	cd components/gmqcc && $(MAKE) clean || true

# Distclean is a deeper clean that removes everything except cached downloads.
distclean: clean
	@echo "Cleaning up all compiled dependencies..."
	rm -rf $(DEPS_DIR)

# =========================================================================
#   Source Archive Download Targets
#
#   All archives are downloaded into the `_source` directory.
# =========================================================================
$(SRC_DIR)/nexuiz-252.zip:
	@echo "Downloading Nexuiz 2.5.2 data..."
	@wget -c -O $@ "https://downloads.sourceforge.net/project/nexuiz/NexuizRelease/Nexuiz%202.5.2/$(notdir $@)"

$(SRC_DIR)/$(MBEDTLSTARGZ):
	@echo "Downloading mbedTLS..."
	@wget -c -O $@ "https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v$(MBEDTLSVERSION).tar.gz"

$(SRC_DIR)/$(FLTKTARGZ):
	@echo "Downloading FLTK..."
	@wget -c -O $@ "https://github.com/fltk/fltk/archive/refs/tags/release-$(FLTKVERSION).tar.gz"

$(SRC_DIR)/$(CURLTARGZ):
	@echo "Downloading cURL..."
	@wget -c -O $@ https://curl.se/download/$(notdir $@)

$(SRC_DIR)/$(LIBOGGTARGZ):
	@echo "Downloading libogg..."
	@wget -c -O $@ "https://github.com/xiph/ogg/releases/download/v$(LIBOGGVERSION)/$(notdir $@)"

$(SRC_DIR)/$(LIBVORBISTARGZ):
	@echo "Downloading libvorbis..."
	@wget -c -O $@ "https://github.com/xiph/vorbis/releases/download/v$(LIBVORBISVERSION)/$(notdir $@)"

$(SRC_DIR)/$(LIBTHEORATARGZ):
	@echo "Downloading libtheora..."
	@wget -c -O $@ https://ftp.osuosl.org/pub/xiph/releases/theora/$(notdir $@)

$(SRC_DIR)/$(FREETYPETARGZ):
	@echo "Downloading FreeType..."
	@wget -c -O $@ https://mirror.accum.se/mirror/gnu.org/savannah/freetype/$(notdir $@)

$(SRC_DIR)/$(SDLTARGZ):
	@echo "Downloading SDL2..."
	@wget -c -O $@ https://www.libsdl.org/release/$(notdir $@)

$(SRC_DIR)/$(JPEGTARGZ):
	@echo "Downloading libjpeg..."
	@wget -c -O $@ https://ijg.org/files/$(notdir $@)

$(SRC_DIR)/$(ZLIBTARGZ):
	@echo "Downloading zlib..."
	@wget -c -O $@ https://zlib.net/$(notdir $@)

$(SRC_DIR)/$(LIBPNGTARGZ):
	@echo "Downloading libpng..."
	@wget -c -O $@ "https://github.com/pnggroup/libpng/archive/refs/tags/v$(LIBPNGVERSION).tar.gz"

$(SRC_DIR)/$(LIBSAMPLERATETARXZ):
	@echo "Downloading libsamplerate..."
	@wget -c -O $@ "https://github.com/libsndfile/libsamplerate/releases/download/$(LIBSAMPLERATEVERSION)/$(notdir $@)"

$(SRC_DIR)/$(LIBMICROHTTPDTARGZ):
	@echo "Downloading libmicrohttpd..."
	@wget -c -O $@ "https://github.com/Karlson2k/libmicrohttpd/releases/download/v$(LIBMICROHTTPDVERSION)/$(notdir $@)"

$(SRC_DIR)/$(OPUSTARGZ):
	@echo "Downloading opus..."
	@wget -c -O $@ "https://github.com/xiph/opus/releases/download/v$(OPUSVERSION)/$(notdir $@)"

$(SRC_DIR)/$(ASSIMPTARGZ):
	@echo "Downloading assimp..."
	@wget -c -O $@ "https://github.com/assimp/assimp/archive/refs/tags/v$(ASSIMPVERSION).tar.gz"

$(SRC_DIR)/$(LIBVPXTARGZ):
	@echo "Downloading libvpx..."
	@wget -c -O $@ "https://github.com/webmproject/libvpx/archive/refs/tags/$(notdir $@)"


# =========================================================================
#   Dependency Build Targets
#
#   Each library is extracted to `_build`, built there, and installed to `_deps`.
# =========================================================================

# ZLIB
$(ZLIBFILES): $(SRC_DIR)/$(ZLIBTARGZ)
	@echo "Building zlib for engine..."
	rm -rf $(BUILD_DIR)/$(ZLIBDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(ZLIBDIR) && \
		CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" ./configure --static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install
	$(RANLIB) $(LIBDIR)/lib/libz.a

$(ZLIBFILES_FLRL): $(SRC_DIR)/$(ZLIBTARGZ)
	@echo "Building zlib for launcher..."
	rm -rf $(BUILD_DIR)/$(ZLIBDIR)-flrl
	tar -C $(BUILD_DIR) -xzf $< && mv $(BUILD_DIR)/$(ZLIBDIR) $(BUILD_DIR)/$(ZLIBDIR)-flrl
	cd $(BUILD_DIR)/$(ZLIBDIR)-flrl && \
		CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" ./configure --static --prefix=$(LIBDIR_FLRL) && \
		$(MAKE) && $(MAKE) install
	$(RANLIB) $(LIBDIR_FLRL)/lib/libz.a

# LIBPNG
$(LIBPNGFILES): $(SRC_DIR)/$(LIBPNGTARGZ) $(ZLIBFILES)
	@echo "Building libpng for engine..."
	rm -rf $(BUILD_DIR)/$(LIBPNGDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(LIBPNGDIR) && \
		CC="$(CC)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --host=$(CROSSPREFIX) --disable-shared --enable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

$(LIBPNGFILES_FLRL): $(SRC_DIR)/$(LIBPNGTARGZ) $(ZLIBFILES_FLRL)
	@echo "Building libpng for launcher..."
	rm -rf $(BUILD_DIR)/$(LIBPNGDIR)-flrl
	tar -C $(BUILD_DIR) -xzf $< && mv $(BUILD_DIR)/$(LIBPNGDIR) $(BUILD_DIR)/$(LIBPNGDIR)-flrl
	cd $(BUILD_DIR)/$(LIBPNGDIR)-flrl && \
		CC="$(CC)" CFLAGS="-I$(LIBDIR_FLRL)/include" LDFLAGS="-L$(LIBDIR_FLRL)/lib" \
		./configure --host=$(CROSSPREFIX) --disable-shared --enable-static --prefix=$(LIBDIR_FLRL) && \
		$(MAKE) && $(MAKE) install

# JPEG
$(JPEGFILES): $(SRC_DIR)/$(JPEGTARGZ)
	@echo "Building jpeg for engine..."
	rm -rf $(BUILD_DIR)/$(JPEGDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(JPEGDIR) && \
		CC="$(CC)" ./configure --disable-shared --host=$(CROSSPREFIX) --enable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

$(JPEGFILES_FLRL): $(SRC_DIR)/$(JPEGTARGZ)
	@echo "Building jpeg for launcher..."
	rm -rf $(BUILD_DIR)/$(JPEGDIR)-flrl
	tar -C $(BUILD_DIR) -xzf $< && mv $(BUILD_DIR)/$(JPEGDIR) $(BUILD_DIR)/$(JPEGDIR)-flrl
	cd $(BUILD_DIR)/$(JPEGDIR)-flrl && \
		CC="$(CC)" ./configure --disable-shared --host=$(CROSSPREFIX) --enable-static --prefix=$(LIBDIR_FLRL) && \
		$(MAKE) && $(MAKE) install

# FREETYPE (shared library)
$(FREETYPEFILES): $(SRC_DIR)/$(FREETYPETARGZ)
	@echo "Building freetype..."
	rm -rf $(BUILD_DIR)/$(FREETYPEDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(FREETYPEDIR) && \
		CC="$(CC)" ./configure --with-png=no --with-harfbuzz=no --with-zlib=no --with-bzip2=no --with-brotli=no \
		--enable-shared --host=$(CROSSPREFIX) --disable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

# LIBSAMPLERATE
$(LIBSAMPLERATEFILES): $(SRC_DIR)/$(LIBSAMPLERATETARXZ)
	@echo "Building libsamplerate..."
	rm -rf $(BUILD_DIR)/$(LIBSAMPLERATEDIR)
	tar -C $(BUILD_DIR) -xJf $<
	cd $(BUILD_DIR)/$(LIBSAMPLERATEDIR) && \
		CFLAGS="-std=c99" ./configure --host=$(CROSSPREFIX) --disable-sndfile --disable-alsa --disable-fftw \
		--disable-shared --enable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

# SDL2
$(SDLFILES): $(SRC_DIR)/$(SDLTARGZ) $(SDLDEPS)
	@echo "Building SDL2..."
	rm -rf $(BUILD_DIR)/$(SDLDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(SDLDIR) && \
		sed -i.bak 's/EXTRA_CFLAGS="$$EXTRA_CFLAGS -Wdeclaration-after-statement -Werror=declaration-after-statement"/EXTRA_CFLAGS="$$EXTRA_CFLAGS -Wdeclaration-after-statement"/' ./configure
ifeq ($(DPTARGET_WIN),y)
	cd $(BUILD_DIR)/$(SDLDIR) && \
		CC="$(CC)" CXX="$(CXX)" host_os=mingw CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --host=$(CROSSPREFIX) --target=$(CROSSPREFIX) --enable-static --disable-shared \
		--enable-libsamplerate --disable-libsamplerate-shared --disable-pthreads --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install
else ifeq ($(DPTARGET_MAC),y)
	cd $(BUILD_DIR)/$(SDLDIR) && \
		CC="$(CC)" CXX="$(CXX)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --host=$(CROSSPREFIX) --target=$(CROSSPREFIX) --x-includes=$(MAC_OS_SDK)/usr/include \
		--disable-cpuinfo --disable-video-x11 --enable-static --disable-shared --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install
else ifeq ($(DPTARGET),android)
ifeq ($(ANDROID_ABI),)
	$(error ANDROID_ABI must be set for Android builds)
endif
	mkdir -p $(BUILD_DIR)/$(SDLDIR)/buildtree
	cd $(BUILD_DIR)/$(SDLDIR) && patch -p1 < ../../SDL2.patch
	cd $(BUILD_DIR)/$(SDLDIR)/buildtree && \
		CC="$(CC) $(STATIC_CXXLIB)" CXX="$(CXX) $(STATIC_CXXLIB)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		cmake -DANDROID=1 -DCMAKE_LIBRARY_PATH=${ANDROID_NDK_ROOT}/usr/lib/${CROSSPREFIX}/$(ANDROID_ABI)/ \
		-DANDROID_NDK=${ANDROID_NDK_HOME} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=$(LIBDIR) \
		-DCMAKE_CROSSCOMPILING=1 -DIMPORTED_NO_SONAME=1 -DNO_SONAME=1 .. && \
		$(MAKE) && $(MAKE) install
	sed -i.bak 's/-I\/usr\/include//' $(LIBDIR)/bin/sdl2-config
	sed -i.bak2 's|-l/[^ ]\+/lib\([^ ]\+\)\.so|-l\1|g' $(LIBDIR)/bin/sdl2-config
	cd $(BUILD_DIR)/$(SDLDIR)/src/hidapi/android/ && \
		$(CXX) -O2 -Wall -I$(LIBDIR)/include `$(LIBDIR)/bin/sdl2-config --cflags` -L$(LIBDIR)/lib hid.cpp \
		$(STATIC_CXXLIB) `$(LIBDIR)/bin/sdl2-config --libs` -llog -shared -o $(HIDAPIFILES)
else # Linux
	cd $(BUILD_DIR)/$(SDLDIR) && \
		CC="$(CC)" CXX="$(CXX)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --host=$(CROSSPREFIX) --target=$(CROSSPREFIX) --enable-static --disable-shared \
		--prefix=$(LIBDIR) --disable-pipewire --disable-libdecor && \
		$(MAKE) && $(MAKE) install
endif

# OGG, VORBIS, THEORA
$(LIBOGGFILES): $(SRC_DIR)/$(LIBOGGTARGZ)
	@echo "Building libogg..."
	rm -rf $(BUILD_DIR)/$(LIBOGGDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(LIBOGGDIR) && \
		CC="$(CC)" ./configure --disable-shared --host=$(CROSSPREFIX) --enable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

$(LIBVORBISFILES): $(SRC_DIR)/$(LIBVORBISTARGZ) $(LIBOGGFILES)
	@echo "Building libvorbis..."
	rm -rf $(BUILD_DIR)/$(LIBVORBISDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(LIBVORBISDIR) && \
		sed -i.bak 's/-force_cpusubtype_ALL//' ./configure && \
		sed -i.bak 's/-mno-ieee-fp//' ./configure && \
		PKG_CONFIG_PATH="$(LIBDIR)/lib/pkgconfig" CC="$(CC)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --disable-shared --host=$(CROSSPREFIX) --enable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

$(LIBTHEORAFILES): $(SRC_DIR)/$(LIBTHEORATARGZ) $(LIBOGGFILES)
	@echo "Building libtheora..."
	rm -rf $(BUILD_DIR)/$(LIBTHEORADIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(LIBTHEORADIR) && \
	    HAVE_PDFLATEX=no HAVE_DOXYGEN=no HAVE_BIBTEX=no \
	    RANLIB="$(RANLIB)" AR="$(AR)" CC="$(CC) $(STATIC_CLIB)" \
	    CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib $(STATIC_CLIB)" \
	    ./configure --disable-examples --disable-shared --enable-static --prefix=$(LIBDIR) --disable-spec \
	    $(if $(filter-out x86_64,$(ARCHSUFFIX)),--disable-asm) \
	    $(if $(filter-out native,$(CROSSPREFIX)),--host=$(CROSSPREFIX)) && \
	    $(MAKE) && $(MAKE) install

# THE REST
$(LIBMICROHTTPDFILES): $(SRC_DIR)/$(LIBMICROHTTPDTARGZ)
	@echo "Building libmicrohttpd..."
	rm -rf $(BUILD_DIR)/$(LIBMICROHTTPDDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(LIBMICROHTTPDDIR) && \
		CC="$(CC)" CFLAGS="-I$(LIBDIR)/include" LDFLAGS="-L$(LIBDIR)/lib" \
		./configure --disable-shared --host=$(CROSSPREFIX) --enable-static --disable-https --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install

$(OPUSFILES): $(SRC_DIR)/$(OPUSTARGZ)
	@echo "Building opus..."
	rm -rf $(BUILD_DIR)/$(OPUSDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(OPUSDIR) && \
		CC="$(CC)" AR="$(AR)" ./configure --enable-static --disable-shared --host=$(CROSSPREFIX) --prefix=$(LIBDIR) --disable-extra-programs && \
		$(MAKE) && $(MAKE) install

$(CURLFILES): $(SRC_DIR)/$(CURLTARGZ)
	@echo "Building curl (shared)..."
	rm -rf $(BUILD_DIR)/$(CURLDIR)
	tar -C $(BUILD_DIR) -xzf $<
ifeq ($(DPTARGET_WIN),y)
	cd $(BUILD_DIR)/$(CURLDIR) && \
		CC="$(CC) $(STATIC_CLIB)" ./configure --without-nghttp2 --without-zlib --enable-shared --host=$(CROSSPREFIX) \
		--disable-static --prefix=$(LIBDIR) --disable-pthreads --with-openssl && \
		$(MAKE) && $(MAKE) install
else
	cd $(BUILD_DIR)/$(CURLDIR) && \
		CC="$(CC) $(STATIC_CLIB)" ./configure --without-nghttp2 --without-ssl --without-gnutls --without-zlib \
		--disable-ldap --enable-shared --host=$(CROSSPREFIX) --disable-static --prefix=$(LIBDIR) && \
		$(MAKE) && $(MAKE) install
endif

$(LIBVPXFILES): $(SRC_DIR)/$(LIBVPXTARGZ)
	@echo "Building libvpx..."
	rm -rf $(BUILD_DIR)/$(LIBVPXDIR)
	# The tar command now correctly extracts into a directory named libvpx-1.15.1, which matches $(LIBVPXDIR)
	tar -C $(BUILD_DIR) -xzf $<
ifeq ($(DPTARGET_MAC),y)
	sed -i.bak s/cstdint/stdint.h/ $(BUILD_DIR)/$(LIBVPXDIR)/vp8/vp8_ratectrl_rtc.h
	sed -i.bak 's/std::unique_ptr<\([^>]*\)>/\1*/' $(BUILD_DIR)/$(LIBVPXDIR)/vp8/vp8_ratectrl_rtc.h
	sed -i.bak s/nullptr/NULL/ $(BUILD_DIR)/$(LIBVPXDIR)/vp8/vp8_ratectrl_rtc.h
	sed -i.bak 's/std::unique_ptr<\([^>]*\)>/\1*/' $(BUILD_DIR)/$(LIBVPXDIR)/vp8/vp8_ratectrl_rtc.cc
	sed -i.bak s/nullptr/NULL/ $(BUILD_DIR)/$(LIBVPXDIR)/vp8/vp8_ratectrl_rtc.cc
endif
	cd $(BUILD_DIR)/$(LIBVPXDIR) && \
		RANLIB="$(RANLIB)" STRIP="$(STRIP)" LD="$(LD)" CC="$(CC)" CXX="$(CXX)" AR="$(AR)" \
		./configure --enable-static --disable-shared --disable-examples --disable-webm-io --disable-vp9 \
		--disable-unit-tests --disable-decode-perf-tests --disable-encode-perf-tests --prefix=$(LIBDIR) \
		--target=$(patsubst linux32,x86-linux-gcc,$(patsubst linux64,x86_64-linux-gcc,$(patsubst win32,x86-win32-gcc,$(patsubst win64,x86_64-win64-gcc,$(patsubst mac32,x86-darwin10-gcc,$(patsubst mac64,x86_64-darwin10-gcc,$(patsubst mac-arm64,arm64-darwin20-gcc,$(patsubst linux-arm64,arm64-linux-gcc,$(DPTARGET))))))))) && \
		$(MAKE) && $(MAKE) install

$(ASSIMPFILES): $(SRC_DIR)/$(ASSIMPTARGZ)
	@echo "Building assimp..."
	rm -rf $(BUILD_DIR)/$(ASSIMPDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(ASSIMPDIR) && find . -iname CMakeLists.txt -exec sed -i.bak s/-Werror//g '{}' ';'
	cd $(BUILD_DIR)/$(ASSIMPDIR) && \
		CC="$(CC)" CXX="$(CXX)" $(CROSSCMAKE) -DBUILD_SHARED_LIBS=1 -DASSIMP_BUILD_TESTS=0 \
		-DASSIMP_WARNINGS_AS_ERRORS=0 -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=$(LIBDIR) -DCMAKE_CROSSCOMPILING=1 && \
		$(MAKE) && $(MAKE) install


# =========================================================================
#   Launcher (flrexuizlauncher) Build Targets
# =========================================================================
$(MBEDTLSFILES_FLRL): $(SRC_DIR)/$(MBEDTLSTARGZ)
	@echo "Building mbedTLS for launcher..."
	rm -rf $(BUILD_DIR)/$(MBEDTLSDIR)
	tar -C $(BUILD_DIR) -xzf $<
	cd $(BUILD_DIR)/$(MBEDTLSDIR) && $(MAKE) AR="$(AR)" CC="$(CC)" lib
	mkdir -p "$(LIBDIR_FLRL)/include" "$(LIBDIR_FLRL)/lib"
	cp -a $(BUILD_DIR)/$(MBEDTLSDIR)/include/* "$(LIBDIR_FLRL)/include/"
	cp $(BUILD_DIR)/$(MBEDTLSDIR)/library/*.a "$(LIBDIR_FLRL)/lib/"

$(CURLFILES_FLRL): $(SRC_DIR)/$(CURLTARGZ) $(MBEDTLSFILES_FLRL)
	@echo "Building curl (static) for launcher..."
	rm -rf "$(BUILD_DIR)/$(CURLDIR)-flrl"
	tar -C $(BUILD_DIR) -xzf $< && mv $(BUILD_DIR)/$(CURLDIR) "$(BUILD_DIR)/$(CURLDIR)-flrl"
	cd "$(BUILD_DIR)/$(CURLDIR)-flrl" && \
		sed -i.bak 's/tst_cflags="yes"/tst_cflags="no"/' ./configure
	cd "$(BUILD_DIR)/$(CURLDIR)-flrl" && \
		CC="$(CC)" CFLAGS="-I$(LIBDIR_FLRL)/include" LDFLAGS="-L$(LIBDIR_FLRL)/lib" \
		./configure --without-nghttp2 --with-mbedtls --without-ssl --without-gnutls --without-zlib \
		--disable-ldap --disable-shared --host=$(CROSSPREFIX) --enable-static --prefix=$(LIBDIR_FLRL) && \
		$(MAKE) && $(MAKE) install

$(FLTKFILES_FLRL): $(SRC_DIR)/$(FLTKTARGZ) $(LIBPNGFILES_FLRL) $(JPEGFILES_FLRL)
	@echo "Building FLTK for launcher..."
	rm -rf "$(BUILD_DIR)/$(FLTKDIR)"
	tar -C $(BUILD_DIR) -xzf $<
	mkdir -p "$(BUILD_DIR)/$(FLTKDIR)/test/editor.app/Contents/"
	cd $(BUILD_DIR)/$(FLTKDIR) && \
		autoconf --force && \
		PKG_CONFIG_PATH="$(LIBDIR_FLRL)/lib/pkgconfig" LDFLAGS="-L$(LIBDIR_FLRL)/lib" \
		CC="$(CC)" CFLAGS="-I$(LIBDIR_FLRL)/include" CXXFLAGS="-I$(LIBDIR_FLRL)/include" \
		CXX="$(CXX) -I$(LIBDIR_FLRL)/include -L$(LIBDIR_FLRL)/lib" fltk_cross_compiling=yes \
		./configure --disable-shared --enable-static --host=$(CROSSPREFIX) --prefix=$(LIBDIR_FLRL) && \
		$(MAKE) && \
		$(MAKE) install

flrexuizlauncher: $(FLTKFILES_FLRL) $(MBEDTLSFILES_FLRL) $(CURLFILES_FLRL)
	@echo "Building Rexuiz Launcher..."
ifeq ($(DPTARGET_WIN),y)
	cd components/flrexuizlauncher && $(MAKE) TARGET=windows clean
	cd components/flrexuizlauncher && PKG_CONFIG_PATH="$(LIBDIR_FLRL)/lib/pkgconfig" PATH="$(LIBDIR_FLRL)/bin:$$PATH" $(MAKE) STRIP=$(STRIP) LINK_FLAGS_EXTRA="$(STATIC_CLIB)" TARGET=windows CXX="$(CXX)" CXXFLAGS="-I$(LIBDIR_FLRL)/include" LDFLAGS="-L$(LIBDIR_FLRL)/lib" WINDRES="$(WINDRES)"
	cp components/flrexuizlauncher/flrexuizlauncher.exe $(DIST_DIR)/Rexuiz/RexuizLauncher.Windows-$(ARCHSUFFIX).exe
else ifeq ($(DPTARGET_MAC),y)
	cd components/flrexuizlauncher && $(MAKE) TARGET=mac clean
	cd components/flrexuizlauncher && PKG_CONFIG_PATH="$(LIBDIR_FLRL)/lib/pkgconfig" PATH="$(LIBDIR_FLRL)/bin:$$PATH" $(MAKE) STRIP=$(STRIP) LINK_FLAGS_EXTRA="$(STATIC_CLIB)" TARGET=mac CXX="$(CXX)" CXXFLAGS="-I$(LIBDIR_FLRL)/include" LDFLAGS="-L$(LIBDIR_FLRL)/lib"
ifneq ($(RCODESIGN),)
	$(RCODESIGN) sign components/flrexuizlauncher/RexuizLauncher.app/Contents/MacOS/flrexuizlauncher
endif
ifeq ($(DPTARGET),mac-arm64)
	rm -rf $(DIST_DIR)/Rexuiz/RexuizLauncher-arm64.app/
	cp -a components/flrexuizlauncher/RexuizLauncher.app/ $(DIST_DIR)/Rexuiz/RexuizLauncher-arm64.app/
else
	rm -rf $(DIST_DIR)/Rexuiz/RexuizLauncher.app/
	cp -a components/flrexuizlauncher/RexuizLauncher.app/ $(DIST_DIR)/Rexuiz/RexuizLauncher.app/
endif
else # Linux
	cd components/flrexuizlauncher && $(MAKE) TARGET=linux clean
	cd components/flrexuizlauncher && PKG_CONFIG_PATH="$(LIBDIR_FLRL)/lib/pkgconfig" PATH="$(LIBDIR_FLRL)/bin:$$PATH" $(MAKE) STRIP=$(STRIP) LINK_FLAGS_EXTRA="$(STATIC_CLIB)" TARGET=linux CXX="$(CXX)" CXXFLAGS="-I$(LIBDIR_FLRL)/include" LDFLAGS="-L$(LIBDIR_FLRL)/lib"
	cp components/flrexuizlauncher/flrexuizlauncher $(DIST_DIR)/Rexuiz/RexuizLauncher.Linux-$(ARCHSUFFIX)
	type rpmbuild && cd components/flrexuizlauncher && rpmbuild --target $(ARCHSUFFIX) -bb flrexuizlauncher.spec
	type dpkg-deb && cd components/flrexuizlauncher && sh build_deb.sh $(ARCHSUFFIX)
endif

# =========================================================================
#   Game Engine & Logic Build
# =========================================================================
engine: $(LIBPNGFILES) $(JPEGFILES) $(ZLIBFILES) $(SDLFILES_FORDP) $(EXTRALIBS_LINKONLY) $(LIBMICROHTTPDFILES) $(OPUSFILES)
	@echo "Building Rexuiz engine..."
	cd $(DPDIR) && $(MAKE) clean $(DPMAKEOPTS)
ifeq ($(DPTARGET),android)
	cd $(DPDIR) && PKG_CONFIG_PATH="$(LIBDIR)/lib/pkgconfig" $(MAKE) android-rexuiz $(DPMAKEOPTS)
else
	cd $(DPDIR) && PKG_CONFIG_PATH="$(LIBDIR)/lib/pkgconfig" $(MAKE) sdl-rexuiz $(DPMAKEOPTS)
ifeq ($(DPTARGET_LINUX),y)
	cd $(DPDIR) && PKG_CONFIG_PATH="$(LIBDIR)/lib/pkgconfig" $(MAKE) sv-rexuiz $(DPMAKEOPTS)
endif
endif

gmqcc:
	@echo "Building gmqcc component..."
	$(MAKE) -C components/gmqcc CXX='$(CXX)' STRIP='$(STRIP)'

update-qc: gmqcc
	@echo "Compiling QuakeC game logic..."
	# We call the '1vs1' Makefile and pass a simple relative path to the compiler.
	# The MSYS2 shell can execute this .exe file directly.
	#cd components/1vs1 && $(MAKE) QCC=../../../gmqcc/gmqcc
	#cd components/1vs1 && $(MAKE) QCC='../../components/gmqcc/gmqcc$(EXE_EXT)'
	cd components/1vs1 && $(MAKE) QCC='../../../gmqcc/gmqcc$(EXE_EXT)'
	# The install step sources files from the component's _build directory.
	install -m 644 components/1vs1/_build/progs.dat \
	                components/1vs1/_build/csprogs.dat \
	                components/1vs1/_build/menu.dat \
	                components/1vs1/_build/rexuiz-extra.cfg \
	                assets/rexuiz.pk3/
	install -m 644 components/1vs1/translations/*.po assets/rexuiz.pk3/
	
# =========================================================================
#   Packaging & Distribution
# =========================================================================
stand-alone: stand-alone-engine stand-alone-data

stand-alone-data: update-qc $(SRC_DIR)/nexuiz-252.zip
	@echo "Packaging game data..."
ifeq ($(DPTARGET),android)
	# Android data packaging logic
	rm -f platforms/rexuiz-android/app/src/main/assets/rexuiz/data/rexuiz.pk3
	rm -f platforms/rexuiz-android/app/src/main/assets/rexuiz/data/rexuiz-data.pk3
	cd assets/rexuiz.pk3 && zip -r $(ROOT_DIR)/platforms/rexuiz-android/app/src/main/assets/rexuiz/data/rexuiz.pk3 .
	cd assets/rexuiz-data.pk3 && zip -r $(ROOT_DIR)/platforms/rexuiz-android/app/src/main/assets/rexuiz/data/rexuiz-data.pk3 .
else
	$(MAKE) update-qc
	# Setup directories in the distribution folder
	mkdir -p $(DIST_DIR)/Rexuiz/sources
	mkdir -p $(DIST_DIR)/Rexuiz/data/dlcache
	echo "https://github.com/kasymovga/rexuiz" > $(DIST_DIR)/Rexuiz/sources/sources.txt
	# Package core data
	rm -f $(DIST_DIR)/Rexuiz/data/rexuiz.pk3 $(DIST_DIR)/Rexuiz/data/rexuiz-data.pk3 $(DIST_DIR)/Rexuiz/data/rexuiz-demos.pk3
	cd assets/rexuiz.pk3 && zip -r $(DIST_DIR)/Rexuiz/data/rexuiz.pk3 .
	cd assets/rexuiz-data.pk3 && zip -r $(DIST_DIR)/Rexuiz/data/rexuiz-data.pk3 .
	cd assets/rexuiz-demos.pk3 && zip -r $(DIST_DIR)/Rexuiz/data/rexuiz-demos.pk3 .
	# Extract legacy data from nexuiz-252.zip
	test -f $(DIST_DIR)/Rexuiz/data/common-spog.pk3 || unzip -j $(SRC_DIR)/nexuiz-252.zip Nexuiz/data/common-spog.pk3 -d $(DIST_DIR)/Rexuiz/data
	test -f $(DIST_DIR)/Rexuiz/gpl.txt || unzip -j $(SRC_DIR)/nexuiz-252.zip Nexuiz/gpl.txt -d $(DIST_DIR)/Rexuiz
	test -f $(DIST_DIR)/Rexuiz/data/dlcache/csprogs.dat.408476.61283 || \
		(rm -f data20091001.pk3 csprogs.dat && \
		unzip -j $(SRC_DIR)/nexuiz-252.zip Nexuiz/data/data20091001.pk3 && \
		unzip -j data20091001.pk3 csprogs.dat && \
		mv csprogs.dat $(DIST_DIR)/Rexuiz/data/dlcache/csprogs.dat.408476.61283 && \
		rm -f data20091001.pk3)
	# Package DLC content from assets/rexdlc
	# We pass the correct path to nexuiz-252.zip as an environment variable.
	NEXUIZ_ZIP_PATH=$(SRC_DIR)/nexuiz-252.zip $(MAKE) -C assets/rexdlc base essential
	cp assets/rexdlc/*.pk3 $(DIST_DIR)/Rexuiz/data/dlcache/
	mv $(DIST_DIR)/Rexuiz/data/dlcache/zzz-rexdlc_base-* $(DIST_DIR)/Rexuiz/data/
	cp $(DIST_DIR)/Rexuiz/data/dlcache/zzz-rexdlc_warpzone.pk3 $(DIST_DIR)/Rexuiz/data/
	for F in $(DIST_DIR)/Rexuiz/data/zzz-rexdlc_* ; do mv "$$F" $(DIST_DIR)/Rexuiz/data/rexuiz-$${F#$(DIST_DIR)/Rexuiz/data/zzz-rexdlc_} ; done
	install -m644 scripts/server-example.cfg $(DIST_DIR)/Rexuiz/data/server-example.cfg
endif

stand-alone-engine: engine $(EXTRALIBS)
	@echo "Installing engine and libraries into distribution folder..."
	mkdir -p $(DIST_DIR)/Rexuiz/server
ifeq ($(DPTARGET),android)
ifeq ($(ANDROID_ARCH),)
	$(error ANDROID_ARCH must be set for Android builds)
endif
	# Android engine installation logic
	mkdir -p platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)
	install -m755 $(DPDIR)/librexuiz-android.so platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)/
	install -m755 $(FREETYPEFILES) platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)/
	install -m755 $(CURLFILES) platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)/
	install -m755 $(HIDAPIFILES) platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)/
	install -m755 $(SDLFILES) platforms/rexuiz-android/app/src/main/jniLibs/$(ANDROID_ARCH)/
	mkdir -p platforms/rexuiz-android/app/src/main/java/org/libsdl/app/
	install -m644 $(BUILD_DIR)/$(SDLDIR)/android-project/app/src/main/java/org/libsdl/app/*.java platforms/rexuiz-android/app/src/main/java/org/libsdl/app/
else ifeq ($(DPTARGET_WIN),y)
	install -m644 $(DPDIR)/rexuiz-sdl-$(ARCHSUFFIX).exe $(DIST_DIR)/Rexuiz/rexuiz-sdl-$(ARCHSUFFIX).exe
	install -m644 scripts/run_server_win$(if $(filter x86_64,$(ARCHSUFFIX)),64,32).cmd $(DIST_DIR)/Rexuiz/server/
	mkdir -p $(DIST_DIR)/Rexuiz/bin$(if $(filter x86_64,$(ARCHSUFFIX)),64,32)
	install -m644 $(CURLFILES) $(DIST_DIR)/Rexuiz/bin$(if $(filter x86_64,$(ARCHSUFFIX)),64,32)/
	install -m644 $(FREETYPEFILES) $(DIST_DIR)/Rexuiz/bin$(if $(filter x86_64,$(ARCHSUFFIX)),64,32)/
ifeq ($(ASSIMP_ENABLE),y)
	install -m644 $(ASSIMPFILES) $(DIST_DIR)/Rexuiz/bin$(if $(filter x86_64,$(ARCHSUFFIX)),64,32)/libassimp-dprm.dll
endif
else ifeq ($(DPTARGET_LINUX),y)
	mkdir -p $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)
	install -m 755 $(DPDIR)/rexuiz-sdl $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)/rexuiz-sdl
	install -m 755 $(DPDIR)/rexuiz-dedicated $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)/rexuiz-dedicated
	install -m644 $(CURLFILES) $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)/libcurl-fallback.so
	install -m644 $(FREETYPEFILES) $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)/libfreetype-fallback.so
ifeq ($(ASSIMP_ENABLE),y)
	install -m644 $(ASSIMPFILES) $(DIST_DIR)/Rexuiz/linux-bins/$(ARCHSUFFIX)/libassimp-dprm.so
endif
	sed 's/@@ARCH@@/$(ARCHSUFFIX)/g;s/@@BINARY_NAME@@/rexuiz-sdl/g' scripts/run_client > $(DIST_DIR)/Rexuiz/rexuiz-linux-sdl-$(ARCHSUFFIX)
	chmod 755 $(DIST_DIR)/Rexuiz/rexuiz-linux-sdl-$(ARCHSUFFIX)
	sed 's/@@ARCH@@/$(ARCHSUFFIX)/g;s/@@BINARY_NAME@@/rexuiz-dedicated/g' scripts/run_server > $(DIST_DIR)/Rexuiz/server/rexuiz-linux-dedicated-$(ARCHSUFFIX)
	chmod 755 $(DIST_DIR)/Rexuiz/server/rexuiz-linux-dedicated-$(ARCHSUFFIX)
	install -m755 scripts/update.sh $(DIST_DIR)/Rexuiz/server/update.sh
else ifeq ($(DPTARGET_MAC),y)
	mkdir -p $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS
	mkdir -p $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/Resources/English.lproj
	install -m 755 scripts/Rexuiz.app/Contents/MacOS/rexuiz-dprm-sdl $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/
	install -m 755 scripts/Rexuiz.app/Contents/PkgInfo $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/
	install -m 755 scripts/Rexuiz.app/Contents/Resources/English.lproj/InfoPlist.strings $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/Resources/English.lproj/
	install -m 755 scripts/Rexuiz.app/Contents/Resources/Rexuiz.icns $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/Resources/
	install -m 755 scripts/Rexuiz.app/Contents/Info.plist $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/
	install -m 755 $(DPDIR)/rexuiz-sdl $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/rexuiz-dprm-sdl-bin
	install -m 755 $(CURLFILES) $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/libcurl-fallback.dylib
	install -m 755 $(FREETYPEFILES) $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/
ifeq ($(ASSIMP_ENABLE),y)
	install -m 755 $(ASSIMPFILES) $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/libassimp-dprm.dylib
endif
ifneq ($(RCODESIGN),)
	$(RCODESIGN) sign $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/rexuiz-dprm-sdl-bin
	$(RCODESIGN) sign $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/libfreetype.dylib
	$(RCODESIGN) sign $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/libcurl-fallback.dylib
ifeq ($(ASSIMP_ENABLE),y)
	$(RCODESIGN) sign $(DIST_DIR)/Rexuiz/$(APPNAME)/Contents/MacOS/libassimp-dprm.dylib
endif
endif
endif